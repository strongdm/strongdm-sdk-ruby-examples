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

# Define a Token
token = SDM::Token.new(
  name: 'ruby-test-rotate-token',
  account_type: 'api',
  duration: 3600,
  permissions: [SDM::Permission::ROLE_LIST, SDM::Permission::USER_LIST]
)

# Create a Token
response = client.accounts.create(token, deadline: deadline)
account = response.account

puts 'Successfully created token.'
puts "\tID: #{account.id}"
puts "\tName: #{account.name}"

# Get old token by name
resp = client.accounts.list("name:" + token.name, deadline: deadline)
if resp.count() != 1
  puts 'Get token by name returned more than one or no results'
  return
end

old_token = resp.first()

# deprecate old token name
deprecated_name = old_token.name + '-deprecated'
account.name = deprecated_name
resp = client.accounts.update(account)
account = resp.account
puts 'Successfully updated old token name.'

# create new token
new_token = SDM::Token.new(
  name: old_token.name,
  account_type: old_token.account_type,
  duration: 3600,
  permissions: Array(old_token.permissions)
)
response = client.accounts.create(new_token, deadline: deadline)
account = response.account

puts 'Successfully created new token.'
puts "\tID: #{account.id}"
puts "\tName: #{account.name}"

client.accounts.delete(old_token.id, deadline: deadline)
puts 'Successfully rotated token.'
