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


require "yaml" # Load the YAML parser.

if Rails.env.development? # Load the fictional supplier catalog in development.
  path = Rails.root.join("seed-supplier.yml") # Resolve the local YAML file from the app root.
  sample = YAML.safe_load_file(path) # Read the YAML as plain Ruby data.
  suppliers = sample["suppliers"] if sample.is_a?(Hash) # Read the top-level supplier list.
  raise ArgumentError, "#{path.basename}: expected a suppliers list" unless suppliers.is_a?(Array) # Reject an invalid file structure.

  allowed_fields = %w[ # Allow only supplier data fields from the template.
    erp_vendor_id name sm_vendor_id source_system primary_email country_code state_name city
    tax_id tax_id_type_code active category business_activity description website ai_comments tags size
  ] # Rails manages IDs and timestamps.

  puts "Importing suppliers..." # Announce the import.
  seen_ids = {} # Track ERP IDs already encountered in this file.

  Supplier.transaction do # Roll back the entire supplier batch if a row fails.
    suppliers.each.with_index(1) do |row, number| # Number the supplier entries for error messages.
      location = "#{path.basename}, supplier entry #{number}" # Identify the entry that fails.
      raise ArgumentError, "#{location}: expected a mapping" unless row.is_a?(Hash) # Require a field map.

      unknown_fields = row.keys - allowed_fields # Catch misspelled or unsupported columns.
      if unknown_fields.any? # Stop before writing a row with unknown fields.
        raise ArgumentError, "#{location}: unknown fields #{unknown_fields.map(&:inspect).join(', ')}" # Show which fields to fix.
      end # Finish checking the fields.

      erp_id = row["erp_vendor_id"] # Read the lookup key.
      name = row["name"] # Read the required supplier name.
      unless erp_id.is_a?(String) && erp_id.present? && name.is_a?(String) && name.present? # Require both fields as nonblank strings.
        raise ArgumentError, "#{location}: erp_vendor_id and name must be nonblank strings" # Explain the required minimum.
      end # Finish validating the required fields.

      erp_id = erp_id.strip # Match the supplier model's ERP ID normalization.
      raise ArgumentError, "#{location}: duplicate ERP ID #{erp_id}" if seen_ids.key?(erp_id) # Reject duplicate IDs within the file.
      seen_ids[erp_id] = true # Remember the ID for subsequent entries.

      if row.key?("tags") && !(row["tags"].is_a?(Array) && row["tags"].all?(String)) # Require tags to be a list of strings when supplied.
        raise ArgumentError, "#{location}: tags must be a list of strings; use [] to clear them" # Explain how to clear tags.
      end # Finish validating tags.

      supplier = Supplier.find_or_initialize_by(erp_vendor_id: erp_id) # Reuse the matching supplier or build a new one.
      supplier.assign_attributes(row.except("erp_vendor_id")) # Apply only the fields supplied in YAML.
      supplier.save! # Run Active Record validations and persist the row.
    rescue ActiveRecord::RecordInvalid => error # Add the YAML entry number to model validation errors.
      raise ArgumentError, "#{location}: #{error.record.errors.full_messages.to_sentence}" # Abort the transaction with an actionable error.
    end # Finish processing the supplier entries.
  end # Commit the supplier batch once every entry succeeds.

  puts "Imported #{suppliers.size} supplier entries." # Report success after the transaction commits.
end # Finish the development-only supplier seed.
