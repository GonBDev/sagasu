require "test_helper"

class Users::RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers # Sign in as the account requesting deletion.
  test "public signup grants only base and cannot create RFQs" do # Verify signup and RFQ authorization together.
    email = "base-signup@example.test" # Identify the account created by this test.
    password = "test-password" # Use a valid Devise password.
    assert_difference("User.count", 1) do # Verify signup succeeds.
      post user_registration_path, params: { # Submit directly to public signup.
        user: { email: email, password: password, password_confirmation: password, role: "admin" } # Try requesting a privileged role.
      } # Finish sending the signup request.
    end # Verify one account was created.
    user = User.find_by!(email: email) # Read the persisted signup account.
    assert_equal ["base"], user.user_roles.pluck(:role) # Verify BASE is the only grant.
    get new_project_path # Try to open the new RFQ form as the signed-in account.
    assert_redirected_to root_path # Verify the project policy denies access.
  end # Finish the signup regression test.
  test "the last admin cannot delete their account" do # Exercise account cancellation with one admin.
  admin = User.create!(email: "last-admin@example.test", password: "test-password") # Create the account requesting deletion.
  grant = admin.user_roles.create!(role: :admin) # Make this account the sole admin.
  sign_in admin # Authenticate as that account.

  delete user_registration_path # Submit Devise's account cancellation request.

  assert_redirected_to edit_user_registration_path # Verify the user returns to account settings.
  assert_equal "The last admin account cannot be deleted.", flash[:alert] # Verify the reason is shown.
  assert User.exists?(admin.id) # Verify the account survives.
  assert UserRole.exists?(grant.id) # Verify its admin grant survives.
  follow_redirect! # Open account settings using the same session.
  assert_response :success # Verify the admin is still signed in.
end # Finish checking the blocked deletion.

test "an admin can delete their account when another admin remains" do # Exercise successful admin account cancellation.
  admin = User.create!(email: "leaving-admin@example.test", password: "test-password") # Create the account requesting deletion.
  other_admin = User.create!(email: "remaining-admin@example.test", password: "test-password") # Create the account that will remain.
  grant = admin.user_roles.create!(role: :admin) # Grant admin access to the departing account.
  remaining_grant = other_admin.user_roles.create!(role: :admin) # Keep a second admin grant in place.
  sign_in admin # Authenticate as the departing admin.

  delete user_registration_path # Submit Devise's account cancellation request.

  assert_response :redirect # Verify Devise redirects after cancellation.
  refute User.exists?(admin.id) # Verify the departing account was deleted.
  refute UserRole.exists?(grant.id) # Verify its dependent grant was deleted.
  assert UserRole.exists?(remaining_grant.id) # Verify the other admin keeps access.
end # Finish checking the successful deletion.
end
