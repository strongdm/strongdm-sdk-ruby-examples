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
  name: 'Ruby Update Workflow Example',
  description: 'Ruby Workflow Description',
  access_rules: [
    {
      "tags": {"env": "dev"},
    }
  ],
)

# Create the Workflow
workflow_response = client.workflows.create(workflow, deadline: deadline)
workflow = workflow_response.workflow

puts 'Successfully created Workflow.'
puts "\tID: #{workflow_response.workflow.id}"

# Update Workflow Name
workflow.name = 'Ruby Update Workflow Example New Name'
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow Name.'
puts "\tName: #{update_response.workflow.name}"

# Update Workflow Description
workflow.description = 'Ruby Update Workflow Example Description'
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow Description.'
puts "\tDescription: #{update_response.workflow.description}"

# Update Workflow Weight
weight = workflow.weight
workflow.weight = weight + 20
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow Weight.'
puts "\tWeight: #{update_response.workflow.weight}"

# Update Workflow AutoGrant
auto = workflow.auto
workflow.auto_grant = !auto
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow AutoGrant.'
puts "\tAutoGrant: #{update_response.workflow.auto_grant}"

# Update Workflow Enabled
# The requirements to enable a workflow are that the workflow must be either set
# up for with auto grant enabled or have one or more WorkflowApprovers created for
# the workflow.
workflow.auto_grant = true
workflow.enabled = true
update_response = client.workflows.update(workflow, deadline: deadline)
puts 'Successfully updated Workflow Enabled.'
puts "\tEnabled: #{update_response.workflow.enabled}"