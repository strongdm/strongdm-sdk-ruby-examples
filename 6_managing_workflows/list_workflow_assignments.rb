# Copyright 2023 StrongDM Inc
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

# Define an auto grant Workflow with initial Access Rules. Note that this
# workflow will be enabled.
workflow = SDM::Workflow.new(
  name: 'Ruby List WorkflowAssignment Example',
  description: 'Ruby Workflow Description',
)

# Create the Workflow
workflow_response = client.workflows.create(workflow, deadline: deadline)
workflow = workflow_response.workflow

puts 'Successfully created Workflow.'
puts "\tID: #{workflow.id}"

# Create a resource - used for workflow assignments
# Set `port_override` to `-1` to auto-generate a port if Port Overrides is enabled.
postgres = SDM::Postgres.new(
    name: 'Ruby Example Postgres Datasource',
    hostname: 'example.strongdm.com',
    port: 5432,
    username: 'example',
    password: 'example',
    database: 'example',
    port_override: 19_400,
    tags: {"env": "example"}
)

resource_response = client.resources.create(postgres, deadline: deadline)
resource_id = resource_response.resource.id

# Update workflow assignments
workflow.access_rules = [{"ids": [resource_id]}]
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow Assignment.'

# List workflow assignments
workflow_assignments = client.workflow_assignmentsy.list('resource:?', resource_id)
puts 'List Workflow Assignments'
for w in workflow_assignments
	puts "\tWorkflowAssignment Workflow ID #{w.workflow_id}"
end

puts 'Successfully list WorkflowAssignment.'