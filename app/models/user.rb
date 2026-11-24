class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :user_roles, dependent: :destroy # Give each account multiple grants and remove them when the account is deleted.
  has_many :projects
  has_many :approvals, foreign_key: :approver_id, inverse_of: :approver
  has_many :reviews

  before_destroy :protect_last_admin, prepend: true # Check before dependent role grants are deleted.

  def has_role?(role) # Check for a specific grant on this account.
    user_roles.exists?(role: role) # Read the grant from the role assignments table.
  end # End the role check.

  private # Keep the account-deletion callback internal.

  def protect_last_admin # Check the remaining admin grants during account deletion.
    UserRole.connection.execute("LOCK TABLE user_roles IN SHARE ROW EXCLUSIVE MODE") # Use the same lock as role revocation.
    # Allow deletion when this account is not the sole admin.
    return unless has_role?(:admin) && UserRole.admin.count == 1

    errors.add(:base, "The last admin account cannot be deleted.") # Explain why the account must remain.
    throw :abort # Stop deletion before dependent records are removed.
  end # Finish the last-admin check.
end
