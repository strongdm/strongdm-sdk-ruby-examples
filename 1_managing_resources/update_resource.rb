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

# Define a Postgres Datasource
postgres = SDM::Postgres.new(
  name: 'Ruby Example Postgres Datasource For Update',
  hostname: 'example.strongdm.com',
  port: 5432,
  username: 'example',
  password: 'example',
  database: 'example',
  port_override: 19_403,
  tags: {"env": "example"}
)

# Create the Datasource
create_response = client.resources.create(postgres, deadline: deadline)

puts 'Successfully created Postgres datasource.'
puts "\tID: #{create_response.resource.id}"
puts "\tName: #{create_response.resource.name}"

# Load the Datasource to update
get_response = client.resources.get(create_response.resource.id, deadline: deadline)
resource = get_response.resource

# Update the fields to change
resource.name = 'Ruby Example Postgres Updated'

# Update the Datasource
update_response = client.resources.update(resource, deadline: deadline)

puts 'Successfully updated Postgres datasource.'
puts "\tID: #{update_response.resource.id}"
puts "\tName: #{update_response.resource.name}"
