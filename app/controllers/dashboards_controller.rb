# app/controllers/dashboards_controller.rb
class DashboardsController < ApplicationController
  before_action :authenticate_user!

  def show
    @personal_info = current_user.personal_info
    @address = current_user.address
    @search_profile = current_user.search_profiles
  end
end
