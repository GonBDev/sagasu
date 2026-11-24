class UserRolesController < ApplicationController
  after_action :verify_authorized # Require a policy check for each role change.
  rescue_from Pundit::NotAuthorizedError, with: :role_access_denied # Return a forbidden response for denied changes.

  before_action :load_user # Scope assignments to the account in the route.

  def create # Grant a role to the selected account.
    assignment = @user.user_roles.build(role: params.require(:user_role).fetch(:role)) # Build the grant for authorization.
    authorize assignment # Check whether the actor can grant this role.
    @user.user_roles.create_or_find_by!(role: assignment.role) # Reuse the existing grant on repeated requests.
    redirect_back fallback_location: root_path, notice: "Role granted.", status: :see_other # Return after saving.
  end # Finish granting the role.

  def destroy # Revoke an existing grant.
    revoked = UserRole.transaction do # Keep the last-admin check and deletion atomic.
      UserRole.connection.execute("LOCK TABLE user_roles IN SHARE ROW EXCLUSIVE MODE") # Serialize role writes while checking the admin count.
      assignment = @user.user_roles.find(params[:id]) # Find the grant under the selected account.
      authorize assignment # Check whether the actor can revoke this role.
      next false if assignment.admin? && UserRole.admin.count == 1 # Keep at least one admin grant.

      assignment.destroy! # Remove the authorized grant.
      true # Report that the deletion succeeded.
    end # Release the lock after the transaction.

    if revoked # Distinguish a successful revocation from the last-admin safeguard.
      redirect_back fallback_location: root_path, notice: "Role revoked.", status: :see_other # Return after revoking.
    else # The requested grant belongs to the last admin.
      redirect_back fallback_location: root_path, alert: "The last admin role cannot be revoked.", status: :see_other # Explain why the grant remains.
    end # Finish responding to the revocation request.
  end # Finish revoking the role.

  private # Keep request helpers internal.

  def load_user # Resolve the account identified by the nested route.
    @user = User.find(params[:user_id]) # Use the route parameter as the target account.
  end # Finish loading the account.

  def role_access_denied # Handle denied grants and revocations.
    head :forbidden # Return HTTP 403.
  end # Finish handling the denial.
end
