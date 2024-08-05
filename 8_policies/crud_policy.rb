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

# Create a 30 second deadline
deadline = Time.now.utc + 30

policy = SDM::Policy.new(
  name: 'forbid-everything',
  description: 'Forbid everything',
  policy: 'forbid ( principal, action, resource );'
)

create_resp = client.policies.create(policy, deadline: deadline)
puts 'Successfully created Policy'
puts "\tID: #{create_resp.policy.id}"
puts "\tName: #{create_resp.policy.name}"

# Note: The `policy` field in `create_resp` can also be used to make an
# update. However, we'll load it from the API to demonstrate `get`.
get_resp = client.policies.get(create_resp.policy.id, deadline: deadline)
puts 'Successfully retrieved policy.'
puts "\tID: #{get_resp.policy.id}"
puts "\tName: #{get_resp.policy.name}"

update_policy = get_resp.policy
update_policy.name = 'forbid-one-thing'
update_policy.description = 'forbid connecting to the bad resource'
update_policy.policy = <<-EOP
forbid (
     principal,
     action == StrongDM::Action::"connect",
     resource == StrongDM::Resource::"rs-123d456789"
);
EOP

# Update the policy with new values
update_resp = client.policies.update(update_policy, deadline: deadline)
puts "Successfully retrieved policy."
puts "\tID: #{update_resp.policy.id}"
puts "\tName: #{update_resp.policy.name}"
puts "\tDescription: #{update_resp.policy.description}"
puts "\tPolicy: #{update_resp.policy.policy}"

# Delete the policy
client.policies.delete(create_resp.policy.id, deadline: deadline)

# Try to retrieve a deleted policy
begin
  client.policies.get(create_resp.policy.id, deadline: deadline)
rescue SDM::NotFoundError
end
