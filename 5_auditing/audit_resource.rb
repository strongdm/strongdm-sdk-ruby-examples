# Copyright 2023 StrongDM Inc
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'strongdm'
require 'time'

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

started_at = Time.now.utc

# Create an example Redis resource.
resource = SDM::Redis.new(
  name: 'example-redis',
  hostname: 'example-redis',
  username: 'example-username',
)

response = client.resources.create(resource)
resource_id = response.resource.id

created_at = Time.now.utc

puts "Created resource with ID #{resource_id} at time #{created_at}"

# Update the name of the resource.
response.resource.name = 'example-redis-renamed'
client.resources.update(response.resource)

renamed_at = Time.now.utc

# Delete the resource.
client.resources.delete(resource_id)

deleted_at = Time.now.utc

# Audit records may take a few seconds to be processed.
sleep(2)

# At a time before its creation the resource does not exist
begin
	client.snapshot_at(started_at).resources.get(resource_id)
	raise 'Resource should not exist before its creation'
rescue SDM::NotFoundError
	puts "Resource does not exist at time #{started_at}"
end

# At the time of its creation the resource was named 'example-redis'
response = client.snapshot_at(created_at).resources.get(resource_id)
puts "Resource had name #{response.resource.name} at time #{created_at}"

# At the time of its rename the resource was named 'example-redis-renamed'
response = client.snapshot_at(renamed_at).resources.get(resource_id)
puts "Resource had name #{response.resource.name} at time #{renamed_at}"

# At a time after its deletion the resource does not exist
begin
  client.snapshot_at(deleted_at).resources.get(resource_id)
  raise 'Resource should not exist after its deletion'
rescue SDM::NotFoundError
	puts "Resource does not exist at time #{deleted_at}"
end

# The history of all changes to this resource and their associated activity
history = client.resources_history.list('id:?', resource_id)
for h in history
	puts "Resource had name #{h.resource.name} at time #{h.timestamp}"
	response = client.activities.get(h.activity_id)
	puts "\t#{response.activity.description}"
end
