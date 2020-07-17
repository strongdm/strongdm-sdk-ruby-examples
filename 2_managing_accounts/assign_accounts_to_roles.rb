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
client = SDM::Client.new(api_access_key, api_secret_key, host: 'api.strongdmdev.com:443')

# Create a user
user = SDM::User.new(
  email: 'example@strongdm.com',
  first_name: 'example',
  last_name: 'example'
)

user_response = client.accounts.create(user)

puts 'Successfully created user.'
puts "  Email: #{user_response.account.email}"
puts "  ID: #{user_response.account.id}"

# Create a role
role = SDM::Role.new(
  name: 'example role'
)

role_response = client.roles.create(role)

puts 'Successfully created role.'
puts "  ID: #{role_response.role.id}"

# Attach the user to the role
grant = SDM::AccountAttachment.new(
  account_id: user_response.account.id,
  role_id: role_response.role.id
)

attachment_response = client.account_attachments.create(grant)

puts 'Successfully created account attachment.'
puts "  ID: #{attachment_response.account_attachment.id}"
