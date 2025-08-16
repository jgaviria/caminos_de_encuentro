# app/controllers/search_profiles_controller.rb
class SearchProfilesController < ApplicationController
  before_action :authenticate_user!

  def index
    @search_profiles = SearchProfile.all
  end
  def new
    @search_profile = current_user.search_profiles.build
    @progress_percentage = 100
  end

  def create
    @search_profile = current_user.search_profiles.build(search_profile_params)
    if @search_profile.save
      redirect_to dashboard_path, notice: "Search profile saved successfully."
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
      redirect_to dashboard_path, notice: "Search profile updated successfully."
    else
      @progress_percentage = 100
      render :edit
    end
  end

  def match
    # Only admins can trigger matches
    unless current_user.admin?
      redirect_to search_profiles_path, alert: "Only administrators can run matching processes."
      return
    end
    
    @profile = SearchProfile.find(params[:id])
    
    # Start background matching job for better performance
    MatchingJob.perform_later(@profile.id)
    
    redirect_to admin_matches_path, notice: "Matching process started for #{@profile.first_name} #{@profile.last_name}. Results will be available shortly."
  end
  

  private

  def calculate_similarity(profile1, profile2)
    # Implement your similarity calculation logic here
    # Return a similarity score as a decimal
  end

  def search_profile_params
    params.require(:search_profile).permit(:first_name, :middle_name, :last_name)
  end
end
