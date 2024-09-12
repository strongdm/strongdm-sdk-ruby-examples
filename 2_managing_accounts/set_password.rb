# Copyright 2024 StrongDM Inc
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

# Create an account
# Setting a password when creating an account is not supported
user = SDM::User.new(
  email: 'ruby-set-password@example.com',
  first_name: 'example',
  last_name: 'example',
  permission_level: SDM::PermissionLevel::USER
)

create_response = client.accounts.create(user)
puts 'Successfully created user.'
puts "\tID: #{create_response.account.id}"
puts "\tEmail: #{create_response.account.email}"

# Password is a write-only field
# The current password is never returned in any responses
raise 'Password not empty' unless create_response.account.password == ''

# Get the account
get_response = client.accounts.get(create_response.account.id)
account = get_response.account
raise 'Password not empty' unless account.password == ''

# Set new password according to organization password complexity requirements
account.password = 'correct horse battery staple'

# Update the account with the new password
update_response = client.accounts.update(account)
raise 'Password not empty' unless update_response.account.password == ''
puts 'Successfully updated password.'
puts "\tID: #{update_response.account.id}"
puts "\tNew password: #{account.password}"
