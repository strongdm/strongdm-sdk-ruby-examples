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

example_policies = [
    SDM::Policy.new(
        name: 'default-permit-policy',
        description: 'a default permit policy',
        policy: 'permit (principal, action, resource);'
    ),
    SDM::Policy.new(
        name: 'permit-sql-select-policy',
        description: 'a permit sql select policy',
        policy: 'permit (principal, action == SQL::Action::"select", resource == Postgres::Database::"*");'
    ),
    SDM::Policy.new(
        name: 'default-forbid-policy',
        description: 'a default forbid policy',
        policy: 'forbid (principal, action, resource);'
    ),
    SDM::Policy.new(
        name: 'forbid-connect-policy',
        description: 'a forbid connect policy',
        policy: 'forbid (principal, action == StrongDM::Action::"connect", resource);'
    ),
    SDM::Policy.new(
        name: 'forbid-sql-delete-policy',
        description: 'a forbid delete policy on all resources',
        policy: 'forbid (principal, action == SQL::Action::"delete", resource == Postgres::Database::"*");'
      )
]


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
deadline = Time.now.utc + 30

policies_to_cleanup = example_policies.map do |p|
  create_resp = client.policies.create(p, deadline: deadline)
  puts "Successfully created Policy"
  puts "\tID: #{create_resp.policy.id}"
  puts "\tName: #{create_resp.policy.name}"
  create_resp.policy
end

# Find policies related to `sql` by Name
puts "Finding all Policies with a name containing 'sql'"
for p in client.policies.list('name:*sql*') do
    puts "\tID: #{p.id}\tName: #{p.name}"
end

# Find policies that forbid based on Policy
puts 'Finding all Policies that forbid'
for p in client.policies.list('policy:forbid*') do
    puts "\tID: #{p.id}\tName: #{p.name}"
end

# Cleanup the policies we created
policies_to_cleanup.each do |p|
  client.policies.delete(p.id)
end
