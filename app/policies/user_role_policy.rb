# frozen_string_literal: true

class UserRolePolicy < ApplicationPolicy
  KEYUSER_MANAGED_ROLES = %w[buyer approver viewer].freeze

  def create?
    manage_role?
  end

  def destroy?
    manage_role?
  end

  private

  def manage_role?
    return false unless user
    return false unless UserRole.roles.key?(record.role)
    return false if record.base? # Signup provisions BASE and role managers cannot revoke it.
    return true if user.has_role?(:admin)

    user.has_role?(:keyuser) && KEYUSER_MANAGED_ROLES.include?(record.role)
  end
end
