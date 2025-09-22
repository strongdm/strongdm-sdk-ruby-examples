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
# Groups CRUD - Complete CRUD operations for Groups
#
# This example demonstrates:
# - Create: Create new groups
# - Read: List and filter groups
# - Update: Modify group properties
# - Delete: Remove groups
# - Includes resource cleanup after demonstration

require 'strongdm'

def main
  puts '=== Groups CRUD Example ==='
  puts

  # Load the SDM API keys from the environment.
  # If these values are not set in your environment,
  # please follow the documentation here:
  # https://www.strongdm.com/docs/api/api-keys/
  api_access_key = ENV['SDM_API_ACCESS_KEY']
  api_secret_key = ENV['SDM_API_SECRET_KEY']

  if api_access_key.nil? || api_secret_key.nil?
    puts 'Error: SDM_API_ACCESS_KEY and SDM_API_SECRET_KEY must be provided'
    return
  end

  # Create the SDM client
  client = SDM::Client.new(api_access_key, api_secret_key)

  # Create a 30 second deadline
  deadline = Time.now.utc + 30

  created_groups = []

  begin
    # === CREATE ===
    puts '=== CREATE OPERATION ==='
    puts 'Creating sample groups...'

    # Create multiple groups with different properties
    groups_to_create = [
      {
        name: 'ExampleGroup1',
        description: 'First example group for CRUD demonstration',
        tags: { 'environment' => 'demo', 'team' => 'engineering', 'purpose' => 'crud-example', 'index' => '1' }
      },
      {
        name: 'ExampleGroup2',
        description: 'Second example group for CRUD demonstration',
        tags: { 'environment' => 'demo', 'team' => 'marketing', 'purpose' => 'crud-example', 'index' => '2' }
      },
      {
        name: 'ExampleGroup3',
        description: 'Third example group for CRUD demonstration',
        tags: { 'environment' => 'demo', 'team' => 'sales', 'purpose' => 'crud-example', 'index' => '3' }
      }
    ]

    groups_to_create.each do |group_data|
      group = SDM::Group.new(
        name: group_data[:name],
        description: group_data[:description],
        tags: group_data[:tags]
      )

      response = client.groups.create(group, deadline: deadline)
      created_groups << response.group

      puts "  Created group: #{response.group.name}"
      puts "    ID: #{response.group.id}"
      puts "    Description: #{response.group.description}"
      puts "    Tags: #{response.group.tags}"
      puts
    end

    puts "Successfully created #{created_groups.length} groups."
    puts

    # === READ ===
    puts '=== READ OPERATIONS ==='

    # List all groups
    puts 'Listing all groups:'
    all_groups = client.groups.list('', deadline: deadline)

    count = 0
    all_groups.each do |group|
      count += 1
      puts "  Group #{count}: #{group.name} (ID: #{group.id})"
    end

    puts

    # List groups with filtering
    puts 'Listing groups filtered by name (showing our created examples):'
    filtered_groups = client.groups.list('name:"ExampleGroup*"', deadline: deadline)

    filtered_count = 0
    filtered_groups.each do |group|
      filtered_count += 1
      puts "  Filtered Group #{filtered_count}: #{group.name}"
      puts "    ID: #{group.id}"
      puts "    Description: #{group.description}"
      puts "    Tags: #{group.tags}"
      puts
    end

    puts "Total filtered groups: #{filtered_count}"
    puts

    # === UPDATE ===
    puts '=== UPDATE OPERATION ==='
    unless created_groups.empty?
      group_to_update = created_groups[0]
      original_name = group_to_update.name

      puts "Updating group: #{original_name}"
      puts "  Original name: #{group_to_update.name}"
      puts "  Original description: #{group_to_update.description}"

      # Update the group's properties
      group_to_update.name = "#{original_name}_Updated"
      group_to_update.description = "#{group_to_update.description} - Updated via CRUD example"

      # Add/update tags
      updated_tags = group_to_update.tags.dup
      updated_tags['updated'] = 'true'
      updated_tags['update_timestamp'] = '2025-09-22'
      group_to_update.tags = updated_tags

      update_response = client.groups.update(group_to_update, deadline: deadline)

      puts "  Updated name: #{update_response.group.name}"
      puts "  Updated description: #{update_response.group.description}"
      puts "  Updated tags: #{update_response.group.tags}"
      puts

      # Update the local reference for cleanup
      created_groups[0] = update_response.group
    end

    puts 'Update operation completed.'
    puts

    # === DEMONSTRATE ADDITIONAL READ OPERATIONS ===
    puts '=== ADDITIONAL READ EXAMPLES ==='

    # Filter by tags
    puts 'Filtering groups by tags (purpose:crud-example):'
    tag_filtered_groups = client.groups.list('tags:purpose="crud-example"', deadline: deadline)

    tag_filtered_groups.each do |group|
      team = group.tags['team'] || 'N/A'
      puts "  Group: #{group.name} - Team: #{team}"
    end
    puts

    # Get specific group by ID
    unless created_groups.empty?
      specific_group_id = created_groups[0].id
      puts "Getting specific group by ID (#{specific_group_id}):"
      specific_group = client.groups.get(specific_group_id, deadline: deadline)
      puts "  Retrieved: #{specific_group.group.name}"
      puts "  Description: #{specific_group.group.description}"
      puts
    end

  rescue StandardError => e
    puts "Error during CRUD operations: #{e}"
  ensure
    # === CLEANUP (DELETE) ===
    puts '=== CLEANUP (DELETE OPERATIONS) ==='
    puts "Cleaning up #{created_groups.length} created groups..."

    created_groups.each do |group|
      begin
        puts "  Deleting group: #{group.name} (ID: #{group.id})"
        client.groups.delete(group.id, deadline: deadline)
        puts "  Successfully deleted: #{group.name}"

        # Verify deletion
        begin
          client.groups.get(group.id, deadline: deadline)
          puts "  Warning: Group #{group.name} still exists after deletion"
        rescue SDM::NotFoundError
          puts "  Confirmed: Group #{group.name} no longer exists"
        rescue StandardError => verify_error
          puts "  Error verifying deletion of #{group.name}: #{verify_error}"
        end

      rescue StandardError => delete_error
        puts "  Error deleting group #{group.name}: #{delete_error}"
      end
      puts
    end

    puts '=== Groups CRUD Example Completed ==='
  end
end

main if __FILE__ == $0