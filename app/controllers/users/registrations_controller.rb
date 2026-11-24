class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def sign_up_params
    attributes = super
    requested_role = params.dig(:user, :role)
    attributes[:role] = requested_role == "viewer" ? "viewer" : "buyer"
    attributes
  end
end
