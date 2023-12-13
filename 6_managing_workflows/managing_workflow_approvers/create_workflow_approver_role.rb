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

# Define a Workflow
workflow = SDM::Workflow.new(
  name: 'Ruby Create WorkflowApprover Example',
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
workflow_id = workflow.id

puts 'Successfully created Workflow.'
puts "\tID: #{workflow_id}"

# Create an approver role - used for creating a workflow approver
role = SDM::Role.new(
    name: 'Ruby Role for Creating Workflow Approver Example'
)
role_response = client.roles.create(role, deadline: deadline)
role_id = role_response.role.id

# Create the WorkflowApprover
workflow_approver = SDM::WorkflowApprover.new(
    workflow_id: workflow_id,
    role_id: role_id,
)
workflow_approver_response = client.workflow_approvers.create(workflow_approver, deadline: deadline)
workflow_approver_id = workflow_approver_response.workflow_approver.id

puts 'Successfully created WorkflowApprover.'
puts "\tID: #{workflow_approver_id}"

