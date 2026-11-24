require "test_helper"

class UserRolesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Authenticate the role manager.

  setup do # Use separate accounts for the actor and the recipient.
    @actor = User.create!(email: "manager@example.test", password: "test-password") # Create the acting account.
    @recipient = User.create!(email: "recipient@example.test", password: "test-password") # Create the target account.
    sign_in @actor # Send requests as the role manager.
  end # Finish setting up the accounts.

  test "key user can grant and revoke buyer without duplicate grants" do # Cover the full grant lifecycle.
    @actor.user_roles.create!(role: :keyuser) # Give the actor permission to manage buyer grants.
    2.times do # Submit the same grant twice.
      post user_user_roles_path(@recipient), params: { user_role: { role: "buyer" } } # Request a buyer grant.
      assert_response :see_other # Verify both requests complete.
    end # Finish retrying the request.
    assert_equal 1, @recipient.user_roles.buyer.count # Verify exactly one buyer grant exists.
    grant = @recipient.user_roles.buyer.sole # Load the persisted grant.
    assert_difference -> { @recipient.user_roles.buyer.count }, -1 do # Verify the authorized revocation removes the grant.
      delete user_user_role_path(@recipient, grant) # Revoke the buyer grant.
      assert_response :see_other # Verify the revocation redirects.
    end # Finish checking the deletion.
  end # Finish testing the buyer grant lifecycle.

  test "key user cannot grant admin or auditor" do # Check privileged roles at the request boundary.
    @actor.user_roles.create!(role: :keyuser) # Give the actor only key-user privileges.
    %w[admin auditor].each do |role| # Try both admin-only grants.
      assert_no_difference -> { @recipient.user_roles.count } do # Ensure the recipient's grants stay unchanged.
        post user_user_roles_path(@recipient), params: { user_role: { role: role } } # Request the restricted role.
        assert_response :forbidden # Verify the policy denies it.
      end # Finish checking the denied grant.
    end # Finish checking both roles.
  end # Finish the privileged-grant test.

  test "admin can revoke another admin but cannot revoke the last grant" do # Check both branches of the admin safeguard.
    last_grant = @actor.user_roles.create!(role: :admin) # Give the actor an admin grant.
    other_grant = @recipient.user_roles.create!(role: :admin) # Create a second admin grant.
    assert_difference -> { UserRole.admin.count }, -1 do # Check that two admins can become one.
      delete user_user_role_path(@recipient, other_grant) # Revoke the other account's grant.
      assert_response :see_other # Verify the revocation redirects.
    end # Finish the successful revocation check.
    assert_no_difference -> { UserRole.admin.count } do # Verify the last grant is protected.
      delete user_user_role_path(@actor, last_grant) # Attempt to revoke the sole remaining grant.
      assert_response :see_other # Verify the safeguard redirects.
    end # Finish checking the blocked revocation.
    assert UserRole.exists?(last_grant.id) # Verify the original admin grant remains.
  end # Finish testing the last-admin safeguard.

  test "role grant must belong to the user in the route" do # Check that nested routes scope the revocation.
    @actor.user_roles.create!(role: :keyuser) # Authorize the actor to revoke buyer grants.
    grant = @recipient.user_roles.create!(role: :buyer) # Store the grant on a different account.
    delete user_user_role_path(@actor, grant) # Submit the recipient's grant under the actor's account.
    assert_response :not_found # Verify the scoped lookup rejects it.
    assert UserRole.exists?(grant.id) # Verify the grant remains intact.
  end # Finish testing the nested lookup.
end
