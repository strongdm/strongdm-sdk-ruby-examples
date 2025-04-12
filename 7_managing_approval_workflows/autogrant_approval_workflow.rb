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

# Define an approval workflow.
approval_workflow = SDM::ApprovalWorkflow.new(
  name: 'Ruby Approval Workflow Example',
  description: 'Ruby Approval Workflow Description',
  approval_mode: 'automatic',
)

# Create the Approval Workflow
approval_workflow_response = client.approval_workflows.create(approval_workflow, deadline: deadline)
approval_workflow = approval_workflow_response.approval_workflow

puts 'Successfully created Approval Workflow.'
puts "\tID: #{approval_workflow.id}"
puts "\tName: #{approval_workflow_response.approval_workflow.name}"

# Update Approval Workflow Name
approval_workflow.name = 'Ruby Update Approval Workflow Example New Name'
update_response = client.approval_workflows.update(approval_workflow, deadline: deadline)
puts 'Successfully updated Approval Workflow Name.'
puts "\tName: #{update_response.approval_workflow.name}"

# Update Approval Workflow Description
approval_workflow.description = 'Ruby Update Approval Workflow Example Description'
update_response = client.approval_workflows.update(approval_workflow, deadline: deadline)
puts 'Successfully updated Approval Workflow Description.'
puts "\tDescription: #{update_response.approval_workflow.description}"

# Update Approval Workflow Approval Mode
approval_workflow.approval_mode = 'manual'
update_response = client.approval_workflows.update(approval_workflow, deadline: deadline)
puts 'Successfully updated Approval Workflow Description.'
puts "\tApproval Mode: #{update_response.approval_workflow.approval_mode}"

# Delete the Approval Workflow
client.approval_workflows.delete(approval_workflow.id, deadline: deadline)
puts 'Successfully deleted Approval Workflow.'