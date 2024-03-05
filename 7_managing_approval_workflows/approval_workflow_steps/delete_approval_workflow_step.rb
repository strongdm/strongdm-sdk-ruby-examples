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

# Define an approval workflow.
# Note that in order to add approval workflow steps, the approval workflow must have approval_mode 'manual'
approval_workflow = SDM::ApprovalWorkflow.new(
  name: 'Ruby Delete Approval Workflow Step Example',
  description: 'Ruby Approval Workflow Description',
  approval_mode: 'manual',
)

# Create the Approval Workflow
approval_workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)
approval_workflow_id = approval_workflow_response.approval_workflow.id

puts 'Successfully created Approval Workflow.'
puts "\tID: #{approval_workflow_id}"

# Define an approval workflow step.
approval_workflow_step = SDM::ApprovalWorkflowStep.new(
  approval_flow_id: approval_workflow_id,
)

# Create the Approval Workflow Step
approval_workflow_step_response = client.approval_workflow_steps.create(approval_workflow_step, deadline: deadline)
approval_workflow_step_id = approval_workflow_step_response.approval_workflow_step.id

puts 'Successfully created Approval Workflow Step.'
puts "\tID: #{approval_workflow_step_id}"

# Delete the Approval Workflow Step
client.approval_workflow_steps.delete(approval_workflow_step_id, deadline: deadline)

puts 'Successfully deleted Approval Workflow Step.'