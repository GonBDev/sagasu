# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).


if Rails.env.development? # Create demo accounts only in development.
  password = ENV.fetch("SAGASU_DEMO_PASSWORD") # Read the password from the local environment.

  demo_accounts = { # List the grants each account receives in addition to BASE.
    "base" => [], # Exercise the default signup access.
    "buyer01" => %i[buyer], # Own the main demo RFQ.
    "buyer02" => %i[buyer approver], # Exercise project isolation and multiple grants.
    "boss" => %i[approver], # Exercise assigned approvals when that workflow is available.
    "manager" => %i[approver viewer], # Exercise organization-wide RFQ viewing.
    "keyuser" => %i[keyuser], # Exercise ordinary role assignment.
    "auditor" => %i[auditor], # Exercise organization-wide read access.
    "admin" => %i[admin] # Provision the development role administrator.
  } # Finish defining the demo accounts.

  demo_accounts.each do |username, roles| # Provision each account by email.
    User.find_or_create_by!(email: "#{username}@sagasu.ai") do |user| # Set defaults for newly created accounts.
      user.name = username.humanize # Set a readable display name.
      user.password = password # Set the initial demo password.
      ([:base] + roles).each do |role| # Give every demo account BASE.
        user.user_roles.build(role: role) # Save the grant with the account.
      end # Finish building the grants.
    end # Preserve existing accounts on reruns.
  end # Finish provisioning demo users.
end # Finish the development-only seed.
