# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    if current_user.admin?
      render "admin_dashboard"
    else
      @personal_info = current_user.personal_info
      @address = current_user.address
      @search_profile = current_user.search_profiles
      render "user_dashboard"
    end
  end
end
