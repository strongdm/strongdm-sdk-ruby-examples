# Copyright 2025 StrongDM Inc
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
# https://www.strongdm.com/docs/api/api-keys/
api_access_key = ENV['SDM_API_ACCESS_KEY']
api_secret_key = ENV['SDM_API_SECRET_KEY']
if api_access_key.nil? || api_secret_key.nil?
  puts 'SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY must be provided'
  return
end

# Create the SDM client
client = SDM::Client.new(api_access_key, api_secret_key)

# Create a 30 second deadline
deadline = Time.now + 30

# Define a User
user = SDM::User.new(
  email: 'ruby-create-user@example.com',
  first_name: 'example',
  last_name: 'example',
  permission_level: SDM::PermissionLevel::TEAM_LEADER
)

# Create a User
response = client.accounts.create(user, deadline: deadline)

puts 'Successfully created user.'
puts "\tID: #{response.account.id}"
puts "\tEmail: #{response.account.email}"

# Assign the first user as manager for another new user
user2 = SDM::User.new(
  email: 'create-user2@example.com',
  first_name: 'example2',
  last_name: 'example2',
  manager_id: response.account.id
)
response2 = client.accounts.create(user2, deadline: deadline)
created_user2 = response2.account

puts 'Successfully created user with manager assignment.'
puts "\tID: #{created_user2.id}"
puts "\tManagerID: #{created_user2.manager_id}"

# Fetch the new user to retrieve resolved manager and SCIM metadata if present.
# resolved_manager_id will be set to the manager ID of the user, if present,
# and will be resolved from manager information from SCIM metadata otherwise.
# If no manager information can be resolved from SCIM metadata and manager ID is not set, 
# resolved_manager_id will have no value.
get_resp = client.accounts.get(created_user2.id, deadline: deadline)
got_user = get_resp.account

puts 'Successfully fetched user.'
puts "\tID: #{got_user.id}"
puts "\tManagerID: #{got_user.manager_id}"
puts "\tResolvedManagerID: #{got_user.resolved_manager_id}"
puts "\tSCIM Metadata: #{got_user.scim}"

# Clear the manager assignment and update the user
got_user.manager_id = ''
update_resp = client.accounts.update(got_user, deadline: deadline)
updated_user = update_resp.account

puts 'Successfully updated user.'
puts "\tID: #{updated_user.id}"
puts "\tManagerID: #{updated_user.manager_id}"
