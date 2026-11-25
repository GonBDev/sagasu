class Users::RegistrationsController < Devise::RegistrationsController
  def destroy # Handle both successful and blocked account deletion.
    unless resource.destroy # Keep the current session when the model blocks deletion.
      redirect_to edit_user_registration_path, alert: resource.errors.full_messages.to_sentence, status: :see_other # Show the reason on the account page.
      return # Stop before Devise's sign-out behavior.
    end # Continue only after the account has been deleted.

    Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name) # Preserve Devise's configured sign-out behavior.
    set_flash_message! :notice, :destroyed # Show Devise's account-deletion confirmation.
    redirect_to after_sign_out_path_for(resource_name), status: Devise.responder.redirect_status # Use Devise's post-sign-out redirect.
  end # Finish the account-deletion action.

  protected

  def build_resource(attributes = {}) # Let Devise build the account before adding its grant.
    super # Build the new user from permitted signup attributes.
    resource.user_roles.build(role: :base) # Save the BASE grant together with the new user.
  end # Finish preparing the signup account.
end
