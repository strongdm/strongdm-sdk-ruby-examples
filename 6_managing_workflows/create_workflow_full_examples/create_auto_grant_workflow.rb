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

# Define an auto grant Workflow with initial Access Rules
workflow = SDM::Workflow.new(
  name: 'Ruby Create Auto Grant Full Workflow Example',
  description: 'Ruby Workflow Description',
  auto_grant: true,
  enabled: true,
  access_rules: [
    {
      "tags": {"env": "dev"},
    }
  ],
)

# Create the Workflow
workflow_response = client.workflows.create(workflow, deadline: deadline)
workflow_id = workflow_response.workflow.id

puts 'Successfully created Workflow.'
puts "\tID: #{workflow_id}"
puts "\tName: #{workflow_response.workflow.name}"

# To allow users access to the resources managed by this workflow, you must
# add workflow roles to the workflow.
# Two steps are needed to add a workflow role:
# Step 1: create a Role
# Step 2: create a WorkflowRole

# Create the Role
role = SDM::Role.new(
    name: 'Ruby Role for Auto Grant Workflow Example'
)
role_response = client.roles.create(role, deadline: deadline)
role_id = role_response.role.id

# Create the WorkflowRole
workflow_role = SDM::WorkflowRole.new(
    workflow_id: workflow_id,
    role_id: role_id,
)
workflow_role_response = client.workflow_roles.create(workflow_role, deadline: deadline)
workflow_role_id = workflow_role_response.workflow_role.id

puts 'Successfully created WorkflowRole.'
puts "\tID: #{workflow_role_id}"