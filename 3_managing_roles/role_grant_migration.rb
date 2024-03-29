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

# Create the SDM client.
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
$client = SDM::Client.new(api_access_key, api_secret_key)

def create_example_resources
  # Create a resource (e.g., Redis)
  redis = SDM::Redis.new()
  redis.name = "example_resource_#{rand(100_000)}"
  redis.hostname = "example.com"
  redis.port_override = rand(3_000...20_000)
  redis.tags = {"env": "staging"}
  $client.resources.create(redis).resource
end

def create_example_role( access_rules)
  # Create a Role
  $client.roles.create(SDM::Role.new(
    name: "exampleRole-#{rand(10_000)}",
    access_rules: access_rules,
  )).role
end

def	create_role_grant_via_access_rules
  resource1 = create_example_resources()
  resource2 = create_example_resources()
  role = create_example_role([{"ids": [resource1.id]}])

  # Add Resource2's ID to the Role's Access Rules
  if role.access_rules.length() == 0
    role.access_rules = [{"ids": []}]
  end
  role.access_rules[0]["ids"] << resource2.id
  $client.roles.update(role).role
end

def delete_role_grant_via_access_rules
  resource1 = create_example_resources()
  resource2 = create_example_resources()
  role = create_example_role([{"ids": [resource1.id, resource2.id]}])

  # Remove the ID of the second resource
  role.access_rules[0]["ids"].reject! {|id| id == resource2.id }
  if role.access_rules[0]["ids"].length() == 0
    role.access_rules = []
  end
  $client.roles.update(role)
end

def list_role_grants_via_access_rules
  resource = create_example_resources
  role = create_example_role([{"ids": [resource.id]}]) 

  # role.access_rules contains each Access Rule associate with the Role
  puts role.access_rules.first["ids"]
end

def main

 	# The RoleGrants API has been deprecated in favor of Access Rules.
 	# When using Access Rules, the best practice is to grant Resources access based on type and tags.
	# If it is _necessary_ to grant access to specific Resources in the same way as Role Grants did,
	# you can use Resource IDs directly in Access Rules as shown in the following examples.

  create_role_grant_via_access_rules
  delete_role_grant_via_access_rules
  list_role_grants_via_access_rules
end

main