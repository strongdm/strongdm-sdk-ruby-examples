# Copyright 2025 StrongDM Inc
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
require "strongdm"

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

# Create an approver account - this account is designated as an approver in the approval workflow created below,
# allowing this user to grant approval
account = SDM::User.new(
    email: 'ruby-create-approval-workflow-approver@example.com',
    first_name: 'Example',
    last_name: 'Approver'
)
account_response = client.accounts.create(account, deadline: deadline)
account_id = account_response.account.id
account2 = SDM::User.new(
    email: 'ruby-create-approval-workflow-approver2@example.com',
    first_name: 'Example',
    last_name: 'Approver'
)
account2_response = client.accounts.create(account2, deadline: deadline)
account2_id = account2_response.account.id

# Create an approver role - this role is designated as an approver in the approval workflow created below,
# allowing any user in this role to grant approval
role = SDM::Role.new(
    name: 'Ruby Role for Creating Approval Workflow Approver Example'
)
role_response = client.roles.create(role, deadline: deadline)
role_id = role_response.role.id

# Define an approval workflow.
approval_workflow = SDM::ApprovalWorkflow.new(
  name: "Example Manual Approval Workflow",
  approval_mode: "manual",
  description: "an approval workflow for demonstration",
  approval_workflow_steps: [
    SDM::ApprovalFlowStep.new(
        quantifier: "any",
        skip_after: 60, # in minutes
        approvers: [
            SDM::ApprovalFlowApprover.new(role_id: role_id)
        ]
    ),
    SDM::ApprovalFlowStep.new(
        quantifier: "all",
        approvers: [
            SDM::ApprovalFlowApprover.new(account_id: account_id),
            SDM::ApprovalFlowApprover.new(account_id: account2_id),
            SDM::ApprovalFlowApprover.new(reference: SDM::ApproverReference::MANAGER_OF_REQUESTER)
        ]
    )
  ]
)

# Create the Approval Workflow
approval_workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)

puts 'Successfully created Approval Workflow.'
puts "\tID: #{approval_workflow_response.approval_workflow.id}"
puts "\tName: #{approval_workflow_response.approval_workflow.name}"
puts "\tDescription: #{approval_workflow_response.approval_workflow.description}"
puts "\tApproval Mode: #{approval_workflow_response.approval_workflow.approval_mode}"
puts "\tNumber of Approval Steps: #{approval_workflow_response.approval_workflow.approval_workflow_steps.length}"

# Update the Approval Workflow
updated_flow_configuration = SDM::ApprovalWorkflow.new(
  id: approval_workflow_response.approval_workflow.id, # required
  name: "Example Manual Approval Workflow",
  approval_mode: "manual",
  description: "an approval workflow for demonstration",
  approval_workflow_steps: [
    SDM::ApprovalFlowStep.new(
        quantifier: "all",
        approvers: [
            SDM::ApprovalFlowApprover.new(role_id: role_id)
        ]
    ),
    SDM::ApprovalFlowStep.new(
        quantifier: "any",
        skip_after: 120, # in minutes
        approvers: [
            SDM::ApprovalFlowApprover.new(account_id: account_id)
        ]
    ),
    SDM::ApprovalFlowStep.new(
        quantifier: "any",
        skip_after: 240, # in minutes
        approvers: [
            SDM::ApprovalFlowApprover.new(account_id: account2_id),
            SDM::ApprovalFlowApprover.new(reference: SDM::ApproverReference::MANAGER_OF_MANAGER_OF_REQUESTER)
        ]
    )
  ]
)

update_response = client.approval_workflows.update(updated_flow_configuration, deadline: deadline)

updated_flow = update_response.approval_workflow

puts 'Successfully updated Approval Workflow.'
puts "\tID: #{updated_flow.id}"
puts "\tName: #{updated_flow.name}"
puts "\tDescription: #{updated_flow.description}"
puts "\tApproval Mode: #{updated_flow.approval_mode}"
puts "\tNumber of Approval Steps: #{updated_flow.approval_workflow_steps.length}"

# Get the Approval Workflow
get_response = client.approval_workflows.get(updated_flow.id, deadline: deadline)
got_approval_flow = get_response.approval_workflow

puts 'Successfully got Approval Workflow.'
puts "\tID: #{got_approval_flow.id}"
puts "\tName: #{got_approval_flow.name}"
puts "\tDescription: #{got_approval_flow.description}"
puts "\tApproval Mode: #{got_approval_flow.approval_mode}"
puts "\tNumber of Approval Steps: #{got_approval_flow.approval_workflow_steps.length}"

# Delete the Approval Workflow
client.approval_workflows.delete(got_approval_flow.id, deadline: deadline)
puts 'Successfully deleted Approval Workflow.'