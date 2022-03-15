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

# Define a Postgres resource
postgres = SDM::Postgres.new(
  name: 'Ruby Example Postgres Resource for Access Rules',
  hostname: 'example.strongdm.com',
  port: 5432,
  username: 'example',
  password: 'example',
  database: 'example',
  port_override: 19_406,
  tags: { "example": "grant-access"},
)

# Create the resource
postgres = client.resources.create(postgres, deadline: deadline).resource

puts 'Successfully created Postgres resource.'
puts "\tID: #{postgres.id}"
puts "\tName: #{postgres.name}"

# Define a role with access rules that grant the resource
role = SDM::Role.new(
  name: 'Ruby Access Rule Example',
  access_rules: [
    {
      "tags": {"example": "grant-access"},
    }
  ],
)

# Create the role
role = client.roles.create(role, deadline: deadline).role

puts 'Successfully created role.'
puts "\tID: #{role.id}"
puts "\tName: #{role.name}"

# Define a user
user = SDM::User.new(
  email: 'ruby-access-rules@example.com',
  first_name: 'example',
  last_name: 'example'
)

# Create a user
user = client.accounts.create(user, deadline: deadline).account

puts 'Successfully created user.'
puts "\tID: #{user.id}"
puts "\tEmail: #{user.email}"

# Define an Account attachment
account_attachment = SDM::AccountAttachment.new(
  account_id: user.id,
  role_id: role.id
)

# Create the attachment
account_attachment = client.account_attachments.create(account_attachment, deadline: deadline).account_attachment

puts 'Successfully created account attachment.'
puts "\tID: #{account_attachment.id}"

# To revoke access, there's 3 options:

# Option 1. delete access rules
role.access_rules = []
role = client.roles.update(role, deadline: deadline).role
puts 'Successfully deleted access rules'

# Option 2. delete account attachment
client.account_attachments.delete(account_attachment.id, deadline: deadline)
puts 'Successfully deleted account attachment'

# Option 3: remove tag from resource
postgres.tags = {}
postgres = client.resources.update(postgres, deadline: deadline).resource
puts 'Successfully removed tag from resource'