# Copyright 2025 StrongDM Inc
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
require "fileutils"
require "json"
require "open3"
require "strongdm"
require "tmpdir"

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

# Create the SDM client
client = SDM::Client.new(api_access_key, api_secret_key)

# The name of an RDP resource that has had queries made against it.
resource_name = "example-rdp"
resources = client.resources.list("name:?", resource_name)
resource = resources.to_a[0]

# Retrieve and display all queries made against this resource.
puts "Queries made against #{resource_name}"
queries = client.queries.list("resource_id:?", resource.id)

for query in queries
  response = client.snapshot_at(query.timestamp).accounts.get(query.account_id)
  account = response.account

  if query.encrypted
    puts "Skipping encrypted query made #{account.email} at #{query.timestamp}"
    puts "See encrypted_query_replay.rb for an example of query decryption."
  elsif query.resource_type == "rdp" && query.duration > 0
    puts "RDP query made by #{account.email} at #{query.timestamp}"

    replay_chunks = client.replays.list("id:?", query.id)

    Dir.mktmpdir(query.id) do |temp_dir|
      # Write out the query in node log format: https://www.strongdm.com/docs/admin/logs/references/post-start/
      query_json = {
        type: "postStart",
        uuid: query.id,
        query: query.query_body
      }.to_json
  
      query_file = File.join(temp_dir, "relay.0000000000.log")
      File.write(query_file, query_json)
  
      chunk_id = 1
      replay_chunks.each do |chunk|
        events = chunk.events.map do |event|
          {
            data: Base64.strict_encode64(event.data),
            duration: event.duration.to_i
          }
        end
  
        # Write out the chunk in node log format: https://www.strongdm.com/docs/admin/logs/references/replay-chunks/
        chunk_json = {
          type: "chunk",
          uuid: query.id,
          chunkId: chunk_id,
          events: events
        }.to_json
  
        chunk_file = File.join(temp_dir, format("relay.%010d.log", chunk_id))
        File.write(chunk_file, chunk_json)
  
        chunk_id += 1
      end
  
      # Run the sdm CLI to render the RDP session, this must be in the path
      log_files = Dir.glob(File.join(temp_dir, "*")).sort
      command = ["sdm", "replay", "rdp", query.id, *log_files]
  
      stdout, stderr, status = Open3.capture3(*command)
      unless status.success?
        warn "Failed to run sdm replay:\n#{stderr}"
        exit 1
      end

      stdout.each_line do |line|
        # This line will contain the location of the rendered mp4
        puts line if line.include?("render complete:")
      end
    end
  end
end
