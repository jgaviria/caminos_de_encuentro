class ApplicationController < ActionController::Base
  before_action :configure_permitted_parameters, if: :devise_controller?

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :first_name, :middle_name, :last_name, :phone_numbers, :profession, :occupation, :address, :personal_story ])
  end

  def after_sign_in_path_for(resource)
    authenticated_root_path
  end
end
