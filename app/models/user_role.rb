class UserRole < ApplicationRecord
  belongs_to :user

  enum :role, {          # Define the roles that can be assigned to an account.
    base: "base",        # Basic signed-in access.
    buyer: "buyer",      # Create and manage owned RFQs.
    approver: "approver", # Review assigned approvals.
    viewer: "viewer",    # Organization-wide operational read access.
    keyuser: "keyuser",  # Manage role assignments.
    admin: "admin",      # Administrative access.
    auditor: "auditor"   # Organization-wide audit read access.
  }, validate: true      # Reject missing or unknown roles when saving.
end
