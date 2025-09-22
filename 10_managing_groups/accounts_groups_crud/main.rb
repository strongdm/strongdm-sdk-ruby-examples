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
# AccountsGroups CRUD - Complete CRUD operations for AccountsGroups
#
# This example demonstrates:
# - Create: Link accounts (users) to groups
# - Read: List and filter account-group relationships
# - Delete: Remove account-group relationships
# - Creates prerequisite accounts and groups
# - Includes complete resource cleanup

require 'strongdm'

def main
  puts '=== AccountsGroups CRUD Example ==='
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

  created_accounts = []
  created_groups = []
  created_account_groups = []

  begin
    # === CREATE PREREQUISITE RESOURCES ===
    puts '=== CREATING PREREQUISITE RESOURCES ==='

    # Create test accounts
    puts 'Creating test accounts...'
    accounts_to_create = [
      {
        email: 'account-group-crud-user1@example.com',
        first_name: 'Test',
        last_name: 'User1'
      },
      {
        email: 'account-group-crud-user2@example.com',
        first_name: 'Test',
        last_name: 'User2'
      },
      {
        email: 'account-group-crud-user3@example.com',
        first_name: 'Test',
        last_name: 'User3'
      }
    ]

    accounts_to_create.each do |account_data|
      user = SDM::User.new(
        email: account_data[:email],
        first_name: account_data[:first_name],
        last_name: account_data[:last_name]
      )

      response = client.accounts.create(user, deadline: deadline)
      created_accounts << response.account

      puts "  Created account: #{response.account.email}"
      puts "    ID: #{response.account.id}"
      puts
    end

    # Create test groups
    puts 'Creating test groups...'
    groups_to_create = [
      {
        name: 'AccountGroupCRUD-Group1',
        description: 'First group for AccountsGroups CRUD demonstration'
      },
      {
        name: 'AccountGroupCRUD-Group2',
        description: 'Second group for AccountsGroups CRUD demonstration'
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

    puts "Successfully created #{created_accounts.length} accounts and #{created_groups.length} groups."
    puts

    # === CREATE ACCOUNT-GROUP RELATIONSHIPS ===
    puts '=== CREATE OPERATIONS ==='
    puts 'Creating account-group relationships...'

    # Create multiple account-group relationships
    relationships_to_create = [
      { account: created_accounts[0], group: created_groups[0] },  # User1 -> Group1
      { account: created_accounts[1], group: created_groups[0] },  # User2 -> Group1
      { account: created_accounts[1], group: created_groups[1] },  # User2 -> Group2
      { account: created_accounts[2], group: created_groups[1] },  # User3 -> Group2
    ]

    relationships_to_create.each do |relationship|
      account_group = SDM::AccountGroup.new(
        account_id: relationship[:account].id,
        group_id: relationship[:group].id
      )

      response = client.accounts_groups.create(account_group, deadline: deadline)
      created_account_groups << response.account_group

      puts '  Created relationship:'
      puts "    ID: #{response.account_group.id}"
      puts "    Account: #{relationship[:account].email} (#{relationship[:account].id})"
      puts "    Group: #{relationship[:group].name} (#{relationship[:group].id})"
      puts
    end

    puts "Successfully created #{created_account_groups.length} account-group relationships."
    puts

    # === READ OPERATIONS ===
    puts '=== READ OPERATIONS ==='

    # List all account-group relationships
    puts 'Listing all account-group relationships:'
    all_account_groups = client.accounts_groups.list('', deadline: deadline)

    count = 0
    all_account_groups.each do |account_group|
      count += 1
      puts "  Relationship #{count}: #{account_group.account_id} -> #{account_group.group_id}"
      puts "    ID: #{account_group.id}"
    end

    puts

    # Filter by specific account ID
    unless created_accounts.empty?
      test_account_id = created_accounts[0].id
      puts "Filtering relationships by account ID (#{test_account_id}):"
      filtered_by_account = client.accounts_groups.list("accountid:\"#{test_account_id}\"", deadline: deadline)

      filtered_by_account.each do |account_group|
        puts "  Account #{test_account_id} is in group: #{account_group.group_id}"
        puts "    Relationship ID: #{account_group.id}"
      end
      puts
    end

    # Filter by specific group ID
    unless created_groups.empty?
      test_group_id = created_groups[0].id
      puts "Filtering relationships by group ID (#{test_group_id}):"
      filtered_by_group = client.accounts_groups.list("groupid:\"#{test_group_id}\"", deadline: deadline)

      filtered_by_group.each do |account_group|
        puts "  Group #{test_group_id} contains account: #{account_group.account_id}"
        puts "    Relationship ID: #{account_group.id}"
      end
      puts
    end

    # Get specific relationship by ID
    unless created_account_groups.empty?
      specific_id = created_account_groups[0].id
      puts "Getting specific account-group relationship by ID (#{specific_id}):"
      specific_relationship = client.accounts_groups.get(specific_id, deadline: deadline)
      puts "  Retrieved relationship: #{specific_relationship.account_group.account_id} -> #{specific_relationship.account_group.group_id}"
      puts "    ID: #{specific_relationship.account_group.id}"
      puts
    end

  rescue StandardError => e
    puts "Error during CRUD operations: #{e}"
  ensure
    # === CLEANUP (DELETE OPERATIONS) ===
    puts '=== CLEANUP (DELETE OPERATIONS) ==='

    # Delete account-group relationships
    unless created_account_groups.empty?
      puts "Deleting #{created_account_groups.length} account-group relationships..."
      created_account_groups.each do |account_group|
        begin
          puts "  Deleting relationship: #{account_group.account_id} -> #{account_group.group_id}"
          client.accounts_groups.delete(account_group.id, deadline: deadline)
          puts "  Successfully deleted relationship ID: #{account_group.id}"

          # Verify deletion
          begin
            client.accounts_groups.get(account_group.id, deadline: deadline)
            puts "  Warning: Relationship #{account_group.id} still exists after deletion"
          rescue SDM::NotFoundError
            puts "  Confirmed: Relationship #{account_group.id} no longer exists"
          rescue StandardError => verify_error
            puts "  Error verifying deletion of relationship #{account_group.id}: #{verify_error}"
          end

        rescue StandardError => delete_error
          puts "  Error deleting relationship #{account_group.id}: #{delete_error}"
        end
        puts
      end
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

    # Delete created accounts
    unless created_accounts.empty?
      puts "Deleting #{created_accounts.length} created accounts..."
      created_accounts.each do |account|
        begin
          puts "  Deleting account: #{account.email} (ID: #{account.id})"
          client.accounts.delete(account.id, deadline: deadline)
          puts "  Successfully deleted account: #{account.email}"
        rescue StandardError => delete_error
          puts "  Error deleting account #{account.email}: #{delete_error}"
        end
      end
      puts
    end

    puts '=== AccountsGroups CRUD Example Completed ==='
  end
end

main if __FILE__ == $0