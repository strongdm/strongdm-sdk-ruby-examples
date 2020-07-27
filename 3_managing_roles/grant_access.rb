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

# Define a Postgres datasource
postgres = SDM::Postgres.new(
  name: 'Example Postgres Datasource',
  hostname: 'example.strongdm.com',
  port: 5432,
  username: 'example',
  password: 'example',
  database: 'example',
  port_override: 19999,
)

# Create the datasource
postgres_response = client.resources.create(postgres, deadline: deadline)

puts 'Successfully created Postgres datasource.'
puts "    ID: #{postgres_response.resource.id}"
puts "  Name: #{postgres_response.resource.name}"

# Define a role
role = SDM::Role.new(
  name: 'example role'
)

# Create the role
role_response = client.roles.create(role, deadline: deadline)

puts 'Successfully created role.'
puts "    ID: #{role_response.role.id}"
puts "  Name: #{role_response.role.name}"

# Define a role grant
role_grant = SDM::RoleGrant.new(
  resource_id: postgres_response.resource.id,
  role_id: role_response.role.id
)

# Create the role grant
grant_response = client.role_grants.create(role_grant, deadline: deadline)

puts 'Successfully created role grant.'
puts "  ID: #{grant_response.role_grant.id}"

# Define a user
user = SDM::User.new(
  email: 'example@example.com',
  first_name: 'example',
  last_name: 'example'
)

# Create a user
user_response = client.accounts.create(user, deadline: deadline)

puts 'Successfully created user.'
puts "     ID: #{user_response.account.id}"
puts "  Email: #{user_response.account.email}"

# Define an Account grant
account_grant = SDM::AccountGrant.new(
  account_id: user_response.account.id,
  resource_id: postgres_response.resource.id
)

# Create the grant
grant_response = client.account_grants.create(account_grant, deadline: deadline)

puts 'Successfully created account grant.'
puts "  ID: #{grant_response.account_grant.id}"
