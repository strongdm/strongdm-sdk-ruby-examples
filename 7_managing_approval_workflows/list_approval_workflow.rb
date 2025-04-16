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

# Create an approver account - this account is designated as an approver in the approval workflow created below,
# allowing this user to grant approval
account = SDM::User.new(
    email: 'ruby-create-approval-workflow-approver@example.com',
    first_name: 'Example',
    last_name: 'Approver'
)
account_response = client.accounts.create(account, deadline: deadline)
account_id = account_response.account.id

# Create an approver role - this role is designated as an approver in the approval workflow created below,
# allowing any user in this role to grant approval
role = SDM::Role.new(
    name: 'Ruby Role for Creating Approval Workflow Approver Example'
)
role_response = client.roles.create(role, deadline: deadline)
role_id = role_response.role.id

# Define an approval workflow.
approval_workflow = SDM::ApprovalWorkflow.new(
  name: "List Example Manual Approval Workflow",
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
            SDM::ApprovalFlowApprover.new(account_id: account_id)
        ]
    )
  ]
)

# Create a Manual Approval Workflow
approval_workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)
manual_flow = approval_workflow_response.approval_workflow

puts 'Successfully created Approval Workflow.'
puts "\tID: #{manual_flow.id}"
puts "\tName: #{manual_flow.name}"
puts "\tDescription: #{manual_flow.description}"
puts "\tApproval Mode: #{manual_flow.approval_mode}"
puts "\tNumber of Approval Steps: #{manual_flow.approval_workflow_steps.length}"

# Define an approval workflow.
approval_workflow = SDM::ApprovalWorkflow.new(
  name: 'List Ruby Approval Workflow Example',
  description: 'Ruby Approval Workflow Description',
  approval_mode: 'automatic',
)

# Create an Autogrant Approval Workflow
approval_workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)
autogrant_flow = approval_workflow_response.approval_workflow

puts 'Successfully created Approval Workflow.'
puts "\tID: #{autogrant_flow.id}"
puts "\tName: #{autogrant_flow.name}"


# List Approval Workflows. Filter by Approval Workflow Name.
client.page_limit = 4
list_response = client.approval_workflows.list("name:?", "List*").to_a
got_approval_flows = Array.new()
list_response.each do |n|
    got_approval_flows.push n
end

puts "Got #{got_approval_flows.length} Approval Workflows with name starting in 'List'"

# List Approval Workflows. Filter by id.
client.page_limit = 4
list_response = client.approval_workflows.list("id:?", manual_flow.id).to_a
got_approval_flows = Array.new()
list_response.each do |n|
    got_approval_flows.push n
end

puts "Got #{got_approval_flows.length} Approval Workflows with id=#{manual_flow.id}"
