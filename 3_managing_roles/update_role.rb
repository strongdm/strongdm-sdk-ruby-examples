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

# Define a role
role = SDM::Role.new(
  name: 'Ruby Role Update Example'
)

# Create the role
create_response = client.roles.create(role, deadline: deadline)
puts 'Successfully created role.'
puts "\tID: #{create_response.role.id}"
puts "\tName: #{create_response.role.name}"

# Get the role
get_response = client.roles.get(create_response.role.id, deadline: deadline)
role = get_response.role

# Set fields
role.name = 'ruby example role updated'

# Update the role
update_response = client.roles.update(role, deadline: deadline)
puts 'Successfully updated role.'
puts "\tID: #{update_response.role.id}"
puts "\tName: #{update_response.role.name}"
