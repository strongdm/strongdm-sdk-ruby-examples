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
# GroupsRoles CRUD - Complete CRUD operations for GroupsRoles
#
# This example demonstrates:
# - Create: Link groups to roles
# - Read: List and filter group-role relationships by group or role
# - Delete: Remove group-role relationships
# - Creates prerequisite groups and roles
# - Includes complete resource cleanup

require 'strongdm'

def main
  puts '=== GroupsRoles CRUD Example ==='
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
  created_roles = []
  created_group_roles = []

  begin
    # === CREATE PREREQUISITE RESOURCES ===
    puts '=== CREATING PREREQUISITE RESOURCES ==='

    # Create test groups
    puts 'Creating test groups...'
    groups_to_create = [
      {
        name: 'GroupRoleCRUD-Group1',
        description: 'First group for GroupsRoles CRUD demonstration'
      },
      {
        name: 'GroupRoleCRUD-Group2',
        description: 'Second group for GroupsRoles CRUD demonstration'
      },
      {
        name: 'GroupRoleCRUD-Group3',
        description: 'Third group for GroupsRoles CRUD demonstration'
      }
    ]

    groups_to_create.each do |group_data|
      group = SDM::Group.new(
        name: group_data[:name],
        description: group_data[:description]
      )

      response = client.groups.create(group, deadline: deadline)
      created_groups << response.group

      puts "  Created group: #{response.group.name}"
      puts "    ID: #{response.group.id}"
      puts
    end

    # Create test roles
    puts 'Creating test roles...'
    roles_to_create = [
      {
        name: 'GroupRoleCRUD-Role1'
      },
      {
        name: 'GroupRoleCRUD-Role2'
      }
    ]

    roles_to_create.each do |role_data|
      role = SDM::Role.new(
        name: role_data[:name],
      )

      response = client.roles.create(role, deadline: deadline)
      created_roles << response.role

      puts "  Created role: #{response.role.name}"
      puts "    ID: #{response.role.id}"
      puts
    end

    puts "Successfully created #{created_groups.length} groups and #{created_roles.length} roles."
    puts

    # === CREATE GROUP-ROLE RELATIONSHIPS ===
    puts '=== CREATE OPERATIONS ==='
    puts 'Creating group-role relationships...'

    # Create multiple group-role relationships
    relationships_to_create = [
      { group: created_groups[0], role: created_roles[0] },  # Group1 -> Role1
      { group: created_groups[1], role: created_roles[0] },  # Group2 -> Role1
      { group: created_groups[1], role: created_roles[1] },  # Group2 -> Role2
      { group: created_groups[2], role: created_roles[1] },  # Group3 -> Role2
    ]

    relationships_to_create.each do |relationship|
      group_role = SDM::GroupRole.new(
        group_id: relationship[:group].id,
        role_id: relationship[:role].id
      )

      response = client.groups_roles.create(group_role, deadline: deadline)
      created_group_roles << response.group_role

      puts '  Created relationship:'
      puts "    ID: #{response.group_role.id}"
      puts "    Group: #{response.group_role.group_id}"
      puts "    Role: #{response.group_role.role_id}"
      puts
    end

    puts "Successfully created #{created_group_roles.length} group-role relationships."
    puts

    # === READ OPERATIONS ===
    puts '=== READ OPERATIONS ==='

    # List all group-role relationships
    puts 'Listing all group-role relationships:'
    all_group_roles = client.groups_roles.list('', deadline: deadline)

    count = 0
    all_group_roles.each do |group_role|
      count += 1
      puts "  Relationship #{count}:"
      puts "    ID: #{group_role.id}"
      puts "    Group ID: #{group_role.group_id}"
      puts "    Role ID: #{group_role.role_id}"
      break if count >= 10  # Limit output for readability
    end
    puts "  Total group-role relationships found: #{count} (showing first 10)"
    puts

    # Filter by specific group ID
    unless created_groups.empty?
      test_group_id = created_groups[0].id
      puts "Filtering relationships by group ID (#{test_group_id}):"
      filtered_by_group = client.groups_roles.list("groupid:\"#{test_group_id}\"", deadline: deadline)

      filtered_by_group.each do |group_role|
        puts "  Group #{group_role.group_id}:"
        puts "    Relationship ID: #{group_role.id}"
        puts "    Role ID: #{group_role.role_id}"
      end
      puts
    end

    # Filter by specific role ID
    unless created_roles.empty?
      test_role_id = created_roles[0].id
      puts "Filtering relationships by role ID (#{test_role_id}):"
      filtered_by_role = client.groups_roles.list("roleid:\"#{test_role_id}\"", deadline: deadline)

      filtered_by_role.each do |group_role|
        puts "  Role #{group_role.role_id}:"
        puts "    Relationship ID: #{group_role.id}"
        puts "    Group ID: #{group_role.group_id}"
      end
      puts
    end

    # Get specific relationship by ID
    unless created_group_roles.empty?
      specific_id = created_group_roles[0].id
      puts "Getting specific group-role relationship by ID (#{specific_id}):"
      specific_relationship = client.groups_roles.get(specific_id, deadline: deadline)
      puts "  Retrieved relationship:"
      puts "    ID: #{specific_relationship.group_role.id}"
      puts "    Group ID: #{specific_relationship.group_role.group_id}"
      puts "    Role ID: #{specific_relationship.group_role.role_id}"
      puts
    end

    # === DEMONSTRATE FILTERING BY NAMES ===
    puts '=== ADDITIONAL FILTERING EXAMPLES ==='

    # Filter by group name pattern
    puts 'Filtering relationships by group name pattern:'
    name_filtered = client.groups_roles.list('groupname:"GroupRoleCRUD-Group*"', deadline: deadline)

    name_filtered.each do |group_role|
      puts "  Found: #{group_role.group_id} -> #{group_role.role_id}"
    end
    puts

  rescue StandardError => e
    puts "Error during CRUD operations: #{e}"
  ensure
    # === CLEANUP (DELETE OPERATIONS) ===
    puts '=== CLEANUP (DELETE OPERATIONS) ==='

    # Delete group-role relationships
    unless created_group_roles.empty?
      puts "Deleting #{created_group_roles.length} group-role relationships..."
      created_group_roles.each do |group_role|
        begin
          puts "  Deleting relationship: #{group_role.group_id} -> #{group_role.role_id}"
          client.groups_roles.delete(group_role.id, deadline: deadline)
          puts "  Successfully deleted relationship ID: #{group_role.id}"

          # Verify deletion
          begin
            client.groups_roles.get(group_role.id, deadline: deadline)
            puts "  Warning: Relationship #{group_role.id} still exists after deletion"
          rescue SDM::NotFoundError
            puts "  Confirmed: Relationship #{group_role.id} no longer exists"
          rescue StandardError => verify_error
            puts "  Error verifying deletion of relationship #{group_role.id}: #{verify_error}"
          end

        rescue StandardError => delete_error
          puts "  Error deleting relationship #{group_role.id}: #{delete_error}"
        end
        puts
      end
    end

    # Delete created roles
    unless created_roles.empty?
      puts "Deleting #{created_roles.length} created roles..."
      created_roles.each do |role|
        begin
          puts "  Deleting role: #{role.name} (ID: #{role.id})"
          client.roles.delete(role.id, deadline: deadline)
          puts "  Successfully deleted role: #{role.name}"
        rescue StandardError => delete_error
          puts "  Error deleting role #{role.name}: #{delete_error}"
        end
      end
      puts
    end

    # Delete created groups
    unless created_groups.empty?
      puts "Deleting #{created_groups.length} created groups..."
      created_groups.each do |group|
        begin
          puts "  Deleting group: #{group.name} (ID: #{group.id})"
          client.groups.delete(group.id, deadline: deadline)
          puts "  Successfully deleted group: #{group.name}"
        rescue StandardError => delete_error
          puts "  Error deleting group #{group.name}: #{delete_error}"
        end
      end
      puts
    end

    puts '=== GroupsRoles CRUD Example Completed ==='
  end
end

main if __FILE__ == $0