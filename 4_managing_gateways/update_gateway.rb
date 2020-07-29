# Copyright 2020 StrongDM Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'strongdm'

# Load the SDM API keys from the environment.
# If these values are not set in your environment,
# please follow the documentation here:
# https://www.strongdm.com/docs/admin-guide/api-credentials/
api_access_key = ENV['SDM_API_ACCESS_KEY']
api_secret_key = ENV['SDM_API_SECRET_KEY']
if api_access_key.nil? || api_secret_key.nil?
  puts 'SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY must be provided'
  return
end

# Create the SDM client
client = SDM::Client.new(api_access_key, api_secret_key)

# Create a 30 second deadline
deadline = Time.now.utc + 30

# Define a gateway
gateway = SDM::Gateway.new(
  name: 'example-gateway',
  listen_address: 'gateway.example.com:5555'
)

# Create the gateway
create_response = client.nodes.create(gateway, deadline: deadline)
puts 'Successfully created gateway.'
puts "\tID: #{create_response.node.id}"
puts "\tName: #{create_response.node.name}"
puts "\tToken: #{create_response.token}"

# Get the gateway
get_response = client.nodes.get(create_response.node.id, deadline: deadline)
gateway = get_response.node

# Set fields
gateway.name = "example-gateway-updated"

# Update the gateway
update_response = client.nodes.update(gateway, deadline: deadline)
puts 'Successfully updated gateway.'
puts "\tID: #{update_response.node.id}"
puts "\tName: #{update_response.node.name}"
