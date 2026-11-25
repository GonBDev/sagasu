require "test_helper"

class UserRolePolicyTest < ActiveSupport::TestCase
  setup do
    @actor = User.create!(email: "role-manager@example.test", password: "test-password")
    @recipient = User.create!(email: "role-recipient@example.test", password: "test-password")
  end

  test "key users can manage only buyer, approver, and viewer grants" do
    @actor.user_roles.create!(role: :keyuser)

    assert_manageable_roles %w[buyer approver viewer]
  end

  test "admins can manage every grant except base" do
    @actor.user_roles.create!(role: :admin)

    assert_manageable_roles %w[buyer approver viewer keyuser auditor admin]
  end

  test "users without a management grant cannot assign or revoke roles" do
    %i[base buyer approver viewer auditor].each do |role|
      @actor.user_roles.create!(role: role)
    end

    assert_manageable_roles []
  end

  test "an admin cannot grant an unknown role" do
    @actor.user_roles.create!(role: :admin)
    assignment = @recipient.user_roles.build(role: "unknown")

    refute UserRolePolicy.new(@actor, assignment).create?
  end

  private

  def assert_manageable_roles(allowed_roles)
    UserRole.roles.each_key do |role|
      assignment = @recipient.user_roles.build(role: role)
      assert_equal allowed_roles.include?(role), UserRolePolicy.new(@actor, assignment).create?,
                   "Unexpected grant permission for #{role}"

      assignment.save!
      assert_equal allowed_roles.include?(role), UserRolePolicy.new(@actor, assignment).destroy?,
                   "Unexpected revoke permission for #{role}"
    end
  end
end
