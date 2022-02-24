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
# https://www.strongdm.com/docs/admin-guide/api-credentials/
$client = SDM::Client.new(ENV["SDM_API_ACCESS_KEY"], ENV["SDM_API_SECRET_KEY"], host: "localhost:8889", insecure: true)

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

def create_and_update_access_rules
  redis = create_example_resources

  # Create a Role with initial Access Rule
  access_rules = [
    {
      "ids": [redis.id],
    },
  ]
  role = create_example_role(access_rules)

  # Update Access Rules
  role.access_rules = [
    {
      "tags": {"env": "staging"}
    },
    {
      "type": "redis"
    }
  ]

  $client.roles.update(role).role
end

# Delete the Role
client.roles.delete(create_response.role.id, deadline: deadline)
puts 'Successfully deleted role.'
