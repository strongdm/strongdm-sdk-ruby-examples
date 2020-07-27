require 'yaml'
require 'strongdm'
require 'net/ldap'
require 'optparse'
require 'logger'

# This script reads from an LDAP server and does the following writes in StrongDM:
# - creates roles for each configured group
# - creates accounts for users in those groups
# - attaches those accounts to their corresponding roles
# - grants resources to these roles based on configured filters
# - detaches accounts from roles, deletes accounts, and deletes grants as necessary

# IMPORTANT CAVEATS:
# - this script can pull existing StrongDM users into its purview. then, if the
#   user is removed from LDAP, it will delete the user.
# - if you need to delete an entire role / group, you'll need to do it manually.
#   this script does not touch roles that are not in the config file.
# - accounts that are in a role not referenced by the config will cause the script
#   to error.  You must manually place those accounts into No Role, or remove them
#   from the LDAP groups.

# Example config file:

# groups:
#   - base: DC=j42,DC=xyz
#     memberof: CN=Other,DC=j42,DC=xyz
#     role: Other
#     resources:
#       - name:*Other*
#       - name:*Multi*
#   - base: DC=j42,DC=xyz
#     memberof: CN=admins,DC=j42,DC=xyz
#     role: admins
#     resources:
#       - name:*admins*
#   - base: DC=j42,DC=xyz
#     memberof: CN=People,DC=j42,DC=xyz
#     role: People
#     resources:
#       - name:*People*

SDM_API_ACCESS_KEY = ENV.fetch('SDM_API_ACCESS_KEY', '')
SDM_API_SECRET_KEY = ENV.fetch('SDM_API_SECRET_KEY', '')
LDAP_HOST = ENV.fetch('LDAP_HOST', '')
LDAP_BIND_DN = ENV.fetch('LDAP_BIND_DN', '')
LDAP_PASSWORD = ENV.fetch('LDAP_PASSWORD', '')

# gets the first item in a list or generator
def first(attrib)
  result = nil
  attrib.each do |item|
    result = item if result.nil?
  end
  result
end

def ldap_sync
  if SDM_API_ACCESS_KEY == '' || SDM_API_SECRET_KEY == '' || LDAP_BIND_DN == ''
    puts 'SDM_API_ACCESS_KEY, SDM_API_SECRET_KEY, and LDAP_BIND_DN must be set'
    exit 1
  end

  plan = false
  verbose = false
  configPath = 'config.yml'
  OptionParser.new do |opts|
    opts.banner = 'Usage ldapSync.rb [options]'
    opts.on('-p', '--plan', 'calculate changes but do not apply them') do |p|
      plan = p
    end
    opts.on('-v', '--verbose', 'print detailed report') do |v|
      verbose = v
    end
    opts.on('-c', '--config FILE', "specify path to config YAML file (default: 'config.yml')") do |v|
      configPath = v
    end
  end.parse!

  begin
    config = YAML.load(File.read(configPath))
  rescue StandardError => e
    raise e, "failed to parse #{configPath}"
  end

  begin
    sdmClient = SDM::Client.new(SDM_API_ACCESS_KEY, SDM_API_SECRET_KEY, host: 'api.strongdm.com:443')
  rescue SDM::RPCError => e
    raise e, 'failed to create StrongDM client'
  end

  ldap = Net::LDAP.new
  ldap.host = LDAP_HOST
  ldap.auth LDAP_BIND_DN, LDAP_PASSWORD
  unless ldap.bind
    puts 'failed to bind LDAP connection - authentication error'
    exit 1
  end

  sdmRoles = {} # map of name to ID
  sdmAccounts = {} # map of email to id
  sdmResources = {} # map of ID to name
  sdmAccountsById = {} # map of id to { :email, :firstName, :lastName }
  sdmAccountsWithAttachments = {} # map of email to id of all accounts that are in the roles we're interested in
  sdmAccountAttachments = {} # map of role name to list of emails
  sdmRoleGrants = {} # map of role name to list of { :resourceId, :grantId }
  ldapRoles = [] # list of names
  ldapAccounts = {} # map of email to { :firstName, :lastName }
  ldapAccountAttachments = {} # map of role name to list of emails
  desiredRoleGrants = {} # map of role name to list of resource IDs

  # get SDM accounts
  sdmClient.accounts.list('').each do |account|
    sdmAccounts[account.email] = account.id
    sdmAccountsById[account.id] = { email: account.email, firstName: account.first_name, lastName: account.last_name }
  end

  # get SDM resources
  sdmClient.resources.list('').each do |resource|
    sdmResources[resource.id] = resource.name
  end

  # loop through groups
  config['groups'].each do |group|
    # get SDM state for this group
    role = first(sdmClient.roles.list('name:?', group['role']))
    if role
      sdmRoles[role.name] = role.id

      # get accounts attached to this role
      accountEmails = []
      sdmClient.account_attachments.list('roleid:?', role.id).each do |attachment|
        sdmAccount = sdmAccountsById[attachment.account_id]
        email = sdmAccount[:email]
        sdmAccountsWithAttachments[email] = attachment.account_id
        accountEmails.push(email)
      end
      sdmAccountAttachments[role.name] = accountEmails

      # get resources granted to this role
      roleGrants = []
      sdmClient.role_grants.list('roleid:?', role.id).each do |grant|
        roleGrants.push({ resourceId: grant.resource_id, grantId: grant.id })
      end
      sdmRoleGrants[role.name] = roleGrants

      # get resources that we want to grant to this role
      filteredResources = {} # map of resource ID to true (to prevent duplicates)
      filters = group['resources'] # list of filter strings
      if filters
        filters.each do |filter|
          sdmClient.resources.list(filter).each do |resource|
            filteredResources[resource.id] = true
          end
        end
        desiredRoleGrants[role.name] = filteredResources.keys
      end
    end

    # get LDAP state for this group
    ldapRoles.push(group['role'].to_s)
    roleAccounts = []
    f = Net::LDAP::Filter.join(
      Net::LDAP::Filter.eq('objectclass', 'user'),
      Net::LDAP::Filter.eq('memberof', group['memberof'])
    )
    ldap.search(base: group['base'], filter: f, return_result: false) do |entry|
      ldapAccounts[first(entry.mail).to_s] = {
        firstName: first(entry.givenname).to_s,
        lastName: first(entry['sn']).to_s
      }
      roleAccounts.push(first(entry.mail).to_s)
    end
    ldapAccountAttachments[group['role'].to_s] = roleAccounts
  end

  # compute diff
  report = {
    createRoles: [],
    deleteAccounts: [],
    updateAccounts: [],
    createAccounts: [],
    createAccountAttachments: [],
    deleteAccountAttachments: [],
    deleteRoleGrants: [],
    createRoleGrants: []
  }
  # createRoles
  ldapRoles.each do |roleName|
    next if sdmRoles[roleName]

    report[:createRoles].push(roleName)
    next if plan

    response = sdmClient.roles.create(SDM::Role.new(name: roleName))
    sdmRoles[roleName] = response.role.id
  end
  # deleteAccounts
  sdmAccountsWithAttachments.each do |email, id|
    next if ldapAccounts[email]

    report[:deleteAccounts].push(email)
    next if plan

    sdmClient.accounts.delete(id)
  end
  # updateAccounts
  sdmAccountsWithAttachments.each do |email, id|
    ldapAccount = ldapAccounts[email]
    next unless ldapAccount

    sdmAccount = sdmAccountsById[id]
    next if (sdmAccount[:firstName] == ldapAccount[:firstName]) && (sdmAccount[:lastName] == ldapAccount[:lastName])

    report[:updateAccounts].push(email)
    next if plan

    sdmClient.accounts.update(SDM::User.new(id: id, first_name: ldapAccount[:firstName], last_name: ldapAccount[:lastName]))
  end
  # createAccounts
  ldapAccounts.each do |email, account|
    next if sdmAccounts[email]

    report[:createAccounts].push(email)
    next if plan

    response = sdmClient.accounts.create(SDM::User.new(email: email, first_name: account[:firstName], last_name: account[:lastName]))
    sdmAccounts[response.account.email] = response.account.id
  end
  # deleteAccountAttachments
  sdmAccountAttachments.each do |roleName, accounts|
    roleId = sdmRoles[roleName]
    ldapAccountsInRole = ldapAccountAttachments[roleName]
    accounts.each do |email|
      next if ldapAccountsInRole&.include?(email)

      report[:deleteAccountAttachments].push({ role: roleName, account: email })
      next if plan

      accountId = sdmAccounts[email]
      attachment = first(sdmClient.account_attachments.list('accountid:? roleid:?', accountId, roleId))
      next unless attachment # already deleted by the deleteAccounts step

      sdmClient.account_attachments.delete(attachment.id)
    end
  end
  # createAccountAttachments
  ldapAccountAttachments.each do |roleName, accounts|
    roleId = sdmRoles[roleName]
    sdmAccountsInRole = sdmAccountAttachments[roleName]
    accounts.each do |email|
      next if sdmAccountsInRole&.include?(email)

      report[:createAccountAttachments].push({ role: roleName, account: email })
      accountId = sdmAccounts[email]
      next if plan

      sdmClient.account_attachments.create(SDM::AccountAttachment.new(account_id: accountId, role_id: roleId))
    end
  end
  # deleteRoleGrants
  sdmRoleGrants.each do |roleName, roleGrants|
    desired = desiredRoleGrants[roleName]
    roleGrants.each do |grant|
      next if desired&.include?(grant[:resourceId])

      resourceName = sdmResources[grant[:resourceId]]
      report[:deleteRoleGrants].push({ role: roleName, resource: resourceName })
      next if plan

      sdmClient.role_grants.delete(grant[:grantId])
    end
  end
  # createRoleGrants
  desiredRoleGrants.each do |roleName, roleGrants|
    roleId = sdmRoles[roleName]
    existing = sdmRoleGrants[roleName]
    roleGrants.each do |resourceId|
      next if existing&.find { |existingGrant| existingGrant[:resourceId] == resourceId }

      resourceName = sdmResources[resourceId]
      report[:createRoleGrants].push({ role: roleName, resource: resourceName })
      next if plan

      sdmClient.role_grants.create(SDM::RoleGrant.new(role_id: roleId, resource_id: resourceId))
    end
  end
  if verbose
    puts JSON.pretty_generate(report)
  else
    puts "Create #{report[:createRoles].length} roles"
    puts "Delete #{report[:deleteAccounts].length} accounts"
    puts "Create #{report[:createAccounts].length} accounts"
    puts "Delete #{report[:deleteAccountAttachments].length} account attachments"
    puts "Create #{report[:createAccountAttachments].length} account attachments"
    puts "Delete #{report[:deleteRoleGrants].length} role grants"
    puts "Create #{report[:createRoleGrants].length} role grants"
  end
end

ldap_sync
