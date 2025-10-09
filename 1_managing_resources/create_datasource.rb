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
deadline = Time.now.utc + 30

# Define a Postgres datasource
postgres = SDM::Postgres.new(
  name: 'Ruby Example Postgres Datasource',
  hostname: 'example.strongdm.com',
  port: 5432,
  username: 'example',
  password: 'example',
  database: 'example',
  # Set `PortOverride` to `-1` to auto-allocate an available port.
  port_override: 19_400,
  # May be set to one of the ResourceIPAllocationMode constants to select between VNM,
  # loopback, or default allocation. If not set, will behave as if configured for
  # 'default'.
  # For more details on Virtual Networking Mode see documentation here:
  # https://docs.strongdm.com/admin/clients/client-networking/virtual-networking-mode
  bind_interface: SDM::ResourceIPAllocationMode::LOOPBACK,
  tags: {"env": "example"}
)

# You can also specify an explicit loopback IP address to bind to if Loopback IP Ranges
# are enabled as documented here:
# https://docs.strongdm.com/admin/clients/client-networking/loopback-ip-ranges
postgres.bind_interface = "127.0.0.2"

# ...Or if your organization has Virtual Networking Mode enabled,
# you may configure the resource's bind interface
# to automatically get an IP allocated upon creation:
postgres.bind_interface = SDM::ResourceIPAllocationMode::VNM

# ...Or specify an explicit VNM IP address to bind to...
postgres.bind_interface = "100.64.0.1"

# Your organization can default either to 'loopback' or 'vnm', and
# SDM::ResourceIPAllocationMode::DEFAULT will honor that.
postgres.bind_interface = SDM::ResourceIPAllocationMode::DEFAULT

# Create the Datasource
response = client.resources.create(postgres, deadline: deadline)

puts 'Successfully created Postgres datasource.'
puts "\tID: #{response.resource.id}"
puts "\tName: #{response.resource.name}"
