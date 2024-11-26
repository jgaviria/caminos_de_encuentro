# app/controllers/search_profiles_controller.rb
class SearchProfilesController < ApplicationController
  before_action :authenticate_user!

  def new
    @search_profile = current_user.search_profiles.build
    @progress_percentage = 100
  end

  def create
    @search_profile = current_user.search_profiles.build(search_profile_params)
    if @search_profile.save
      redirect_to dashboard_path, notice: 'Search profile saved successfully.'
    else
      @progress_percentage = 100
      render :new
    end
  end
  def edit
    @search_profile = current_user.search_profile
    @progress_percentage = 100
  end

  def update
    @search_profile = current_user.search_profile
    if @search_profile.update(search_profile_params)
      redirect_to dashboard_path, notice: 'Search profile updated successfully.'
    else
      @progress_percentage = 100
      render :edit
    end
  end

  private

  def search_profile_params
    params.require(:search_profile).permit(:first_name, :middle_name, :last_name)
  end
end
