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

puts 'Example showing how to create approval workflows using groups as approvers'

# Create approver groups - these groups will be designated as approvers
timestamp = Time.now.to_i
security_group = SDM::Group.new(name: "Security Team #{timestamp}")
security_group_response = client.groups.create(security_group, deadline: deadline)
security_group_id = security_group_response.group.id
puts "Created Security Team group: #{security_group_id}"

admin_group = SDM::Group.new(name: "Administrators #{timestamp}")
admin_group_response = client.groups.create(admin_group, deadline: deadline)
admin_group_id = admin_group_response.group.id
puts "Created Administrators group: #{admin_group_id}"

devops_group = SDM::Group.new(name: "DevOps Team #{timestamp}")
devops_group_response = client.groups.create(devops_group, deadline: deadline)
devops_group_id = devops_group_response.group.id
puts "Created DevOps Team group: #{devops_group_id}"

# Create some users to add to groups (demonstrating group membership)
security_user = SDM::User.new(
  email: "security-lead-#{timestamp}@example.com",
  first_name: 'Security',
  last_name: 'Lead'
)
security_user_response = client.accounts.create(security_user, deadline: deadline)
security_user_id = security_user_response.account.id

admin_user = SDM::User.new(
  email: "admin-user-#{timestamp}@example.com",
  first_name: 'Admin',
  last_name: 'User'
)
admin_user_response = client.accounts.create(admin_user, deadline: deadline)
admin_user_id = admin_user_response.account.id

# Add users to their respective groups
security_account_group = SDM::AccountGroup.new(
  account_id: security_user_id,
  group_id: security_group_id
)
client.accounts_groups.create(security_account_group, deadline: deadline)
puts 'Added security user to Security Team group'

admin_account_group = SDM::AccountGroup.new(
  account_id: admin_user_id,
  group_id: admin_group_id
)
client.accounts_groups.create(admin_account_group, deadline: deadline)
puts 'Added admin user to Administrators group'

# Create a manual approval workflow with groups as approvers
approval_workflow = SDM::ApprovalWorkflow.new(
  name: "Group-Based Approval Workflow #{timestamp}",
  description: 'A workflow demonstrating group-based approvers',
  approval_mode: 'manual',
  approval_workflow_steps: [
    # Step 1: Any member of the Security Team can approve
    SDM::ApprovalFlowStep.new(
      quantifier: 'any',
      approvers: [
        SDM::ApprovalFlowApprover.new(group_id: security_group_id)
      ]
    ),
    # Step 2: All specified groups must approve
    SDM::ApprovalFlowStep.new(
      quantifier: 'all',
      skip_after: 7200, # 2 hours in seconds
      approvers: [
        SDM::ApprovalFlowApprover.new(group_id: admin_group_id),     # Administrators group
        SDM::ApprovalFlowApprover.new(group_id: devops_group_id),   # DevOps Team group
        SDM::ApprovalFlowApprover.new(reference: SDM::ApproverReference::MANAGER_OF_REQUESTER) # Plus manager
      ]
    ),
    # Step 3: Mixed approvers - combination of groups and references
    SDM::ApprovalFlowStep.new(
      quantifier: 'any',
      skip_after: 3600, # 1 hour in seconds
      approvers: [
        SDM::ApprovalFlowApprover.new(group_id: security_group_id),  # Security Team
        SDM::ApprovalFlowApprover.new(group_id: admin_group_id),     # Administrators
        SDM::ApprovalFlowApprover.new(reference: SDM::ApproverReference::MANAGER_OF_MANAGER_OF_REQUESTER)
      ]
    )
  ]
)

workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)
created_workflow = workflow_response.approval_workflow

puts "\nSuccessfully created group-based approval workflow."
puts "\tID: #{created_workflow.id}"
puts "\tName: #{created_workflow.name}"
puts "\tDescription: #{created_workflow.description}"
puts "\tNumber of Approval Steps: #{created_workflow.approval_workflow_steps.length}"

created_workflow.approval_workflow_steps.each_with_index do |step, index|
  puts "\nStep #{index + 1}:"
  puts "\tQuantifier: #{step.quantifier}"
  puts "\tSkip After: #{step.skip_after} seconds" if step.skip_after && step.skip_after > 0
  puts "\tApprovers:"
  step.approvers.each do |approver|
    if !approver.account_id.nil? && !approver.account_id.empty?
      puts "\t\t- Account ID: #{approver.account_id}"
    elsif !approver.role_id.nil? && !approver.role_id.empty?
      puts "\t\t- Role ID: #{approver.role_id}"
    elsif !approver.group_id.nil? && !approver.group_id.empty?
      puts "\t\t- Group ID: #{approver.group_id}"
    elsif !approver.reference.nil?
      puts "\t\t- Reference: #{approver.reference}"
    end
  end
end

# Demonstrate updating workflow to use different group combinations
updated_workflow = SDM::ApprovalWorkflow.new(
  id: created_workflow.id,
  name: "Updated Group-Based Approval Workflow #{timestamp}",
  description: 'Updated workflow with different group approver combinations',
  approval_mode: 'manual',
  approval_workflow_steps: [
    # Single step with multiple group options
    SDM::ApprovalFlowStep.new(
      quantifier: 'any',
      skip_after: 86400, # 24 hours in seconds
      approvers: [
        SDM::ApprovalFlowApprover.new(group_id: security_group_id),
        SDM::ApprovalFlowApprover.new(group_id: admin_group_id),
        SDM::ApprovalFlowApprover.new(group_id: devops_group_id)
      ]
    )
  ]
)

updated_response = client.approval_workflows.update(updated_workflow, deadline: deadline)
updated_workflow_obj = updated_response.approval_workflow

puts "\nSuccessfully updated approval workflow:"
puts "\tNew Name: #{updated_workflow_obj.name}"
puts "\tNew Description: #{updated_workflow_obj.description}"
puts "\tSteps after update: #{updated_workflow_obj.approval_workflow_steps.length}"

step = updated_workflow_obj.approval_workflow_steps[0]
puts "\tApprovers in updated step (any of these groups can approve):"
step.approvers.each do |approver|
  puts "\t\t- Group ID: #{approver.group_id}" if !approver.group_id.nil? && !approver.group_id.empty?
end

puts "\nExample demonstrates:"
puts '  • Creating groups to act as approvers'
puts '  • Adding users to groups (group membership)'
puts '  • Using group_id in approval workflow steps'
puts '  • Combining group approvers with other approver types'
puts '  • Different quantifiers (any/all) for group-based approval'

# Clean up - delete the approval workflow
client.approval_workflows.delete(updated_workflow_obj.id, deadline: deadline)
puts "\nCleaned up approval workflow."