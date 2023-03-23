# Copyright 2020 StrongDM Inc
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require "base64"
require "json"
require "openssl"
require "openssl/oaep"

require "strongdm"

# Load the SDM API keys from the environment.
# If these values are not set in your environment,
# please follow the documentation here:
# https://www.strongdm.com/docs/api/api-keys/
api_access_key = ENV["SDM_API_ACCESS_KEY"]
api_secret_key = ENV["SDM_API_SECRET_KEY"]
if api_access_key.nil? || api_secret_key.nil?
  puts "SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY must be provided"
  return
end

# Load the private key for query and replay decryption.
# This environment variable should contain the path to the private encryption
# key configured for StrongDM remote log encryption.
private_key_file = ENV["SDM_LOG_PRIVATE_KEY_FILE"]
if private_key_file.nil?
  puts "SDM_LOG_PRIVATE_KEY_FILE must be provided for this example"
  return
end
private_key = OpenSSL::PKey::RSA.new(File.read(private_key_file))

# Create the SDM client
client = SDM::Client.new(api_access_key, api_secret_key)

# The name of an SSH resource that has had queries made against it.
resource_name = "example-ssh"
resources = client.resources.list("name:?", resource_name)
resource = resources.to_a[0]

# Retrieve and display all queries made against this resource.
puts "Queries made against #{resource_name}"
queries = client.queries.list("resource_id:?", resource.id)

# This method demonstrates how to decrypt encrypted query/replay data
def decrypt_query_data(private_key, encrypted_query_key, encrypted_data)
  # Use the organization's private key to decrypt the symmetric key
  sym_key = private_key.private_decrypt_oaep(
    Base64.decode64(encrypted_query_key),
    "",
    OpenSSL::Digest::SHA256,
    OpenSSL::Digest::SHA256,
  )
  # Use the symmetric key to decrypt the data
  cipher = OpenSSL::Cipher::AES256.new(:CBC)
  cipher.decrypt
  cipher.padding = 0
  cipher.key = sym_key
  cipher.iv = encrypted_data[0..cipher.block_size - 1]
  ciphertext = encrypted_data[cipher.block_size..]
  plaintext = cipher.update(ciphertext) + cipher.final
  return plaintext.gsub(/\x00+$/, "")
end

for query in queries
  response = client.snapshot_at(query.timestamp).accounts.get(query.account_id)
  account = response.account

  if query.encrypted
    puts "Decrypting encrypted query"
    query.query_body = decrypt_query_data(
      private_key,
      query.query_key,
      Base64.decode64(query.query_body),
    )
    query.replayable = JSON.parse(query.query_body)["type"] == "shell"
  end

  if query.replayable
    puts "Replaying query made by #{account.email} at #{query.timestamp}"
    replay_parts = client.replays.list("id:?", query.id)
    for part in replay_parts
      if query.encrypted
        events = JSON.parse(
          decrypt_query_data(private_key, query.query_key, part.data)
        )
        part.events = events.map do |e|
          SDM::ReplayChunkEvent.new(
            data: Base64.decode64(e["data"]),
            duration: e["duration"] / 1000.0,
          )
        end
      end
      for event in part.events
        print(event.data)
        sleep(event.duration)
      end
    end
  else
    command = JSON.parse(query.query_body)["command"]
    puts "Command run by #{account.email} at #{query.timestamp}: #{command}"
  end
end
