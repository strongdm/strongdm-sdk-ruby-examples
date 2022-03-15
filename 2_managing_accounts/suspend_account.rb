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
deadline = Time.now + 30

# Define a User
user = SDM::User.new(
  email: 'ruby-suspend@example.com',
  first_name: 'example',
  last_name: 'example'
)

# Create a User
create_response = client.accounts.create(user, deadline: deadline)
puts 'Successfully created user.'
puts "\tID: #{create_response.account.id}"
puts "\tEmail: #{create_response.account.email}"

# Get the account
get_response = client.accounts.get(create_response.account.id, deadline: deadline)
account = get_response.account

# Set fields
account.suspended = true

# Update the account
update_response = client.accounts.update(account, deadline: deadline)
puts 'Successfully suspended account.'
puts "\tID: #{update_response.account.id}"
puts "\tSuspended: #{update_response.account.suspended}"
