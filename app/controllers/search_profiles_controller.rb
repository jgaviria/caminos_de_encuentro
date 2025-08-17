# app/controllers/search_profiles_controller.rb
class SearchProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :initialize_search_profile_session, only: [:step1, :step2, :step3]

  def index
    @search_profiles = SearchProfile.all
  end
  
  def new
    # Redirect to step 1 for new multi-step flow
    redirect_to step1_search_profiles_path(locale: I18n.locale)
  end

  # Step 1: Basic Information
  def step1
    if request.post?
      # Handle form submission from step 1
      session[:search_profile_data] ||= {}
      if step1_params.present?
        session[:search_profile_data].merge!(step1_params)
        redirect_to step2_search_profiles_path(locale: I18n.locale)
      else
        @search_profile_data = session[:search_profile_data] || {}
        @progress_percentage = 33
        flash.now[:alert] = "Please fill in the required fields."
        render :step1
      end
    else
      # Display step 1 form
      @search_profile_data = session[:search_profile_data] || {}
      @progress_percentage = 33
    end
  end

  # Step 2: Location Information  
  def step2
    if request.post?
      # Handle form submission from step 2
      session[:search_profile_data] ||= {}
      session[:search_profile_data].merge!(step2_params) if step2_params.present?
      redirect_to step3_search_profiles_path(locale: I18n.locale)
    else
      # Display step 2 form
      redirect_to step1_search_profiles_path(locale: I18n.locale) unless session[:search_profile_data].present?
      @search_profile_data = session[:search_profile_data] || {}
      @progress_percentage = 67
    end
  end

  # Step 3: Review and Create
  def step3
    # Always display step 3 (review page)
    redirect_to step1_search_profiles_path(locale: I18n.locale) unless session[:search_profile_data].present?
    @search_profile_data = session[:search_profile_data] || {}
    @progress_percentage = 100
  end

  def create
    # Final creation from step 3
    all_data = session[:search_profile_data] || {}
    
    # Split data into search_profile and address parts
    search_profile_data = all_data.slice('first_name', 'middle_name', 'last_name')
    address_data = all_data.slice('country', 'state', 'city', 'neighborhood', 'street_address', 'postal_code')
    
    @search_profile = current_user.search_profiles.build(search_profile_data)
    
    if @search_profile.save
      # Create associated address if address data exists
      if address_data.any? { |k, v| v.present? }
        @search_profile.create_address(address_data)
      end
      
      session[:search_profile_data] = nil # Clear session data
      redirect_to dashboard_path(locale: I18n.locale), notice: "Search profile created successfully."
    else
      @search_profile_data = all_data
      @progress_percentage = 100
      render :step3
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

  def initialize_search_profile_session
    session[:search_profile_data] ||= {}
  end

  def step1_params
    params.require(:search_profile).permit(:first_name, :middle_name, :last_name) if params[:search_profile]
  end

  def step2_params
    params.require(:address).permit(:country, :state, :city, :neighborhood, :street_address, :postal_code) if params[:address]
  end

  def step3_params
    # Any additional params for step 3 (review/confirmation)
    {}
  end

  def calculate_similarity(profile1, profile2)
    # Implement your similarity calculation logic here
    # Return a similarity score as a decimal
  end

  def search_profile_params
    params.require(:search_profile).permit(:first_name, :middle_name, :last_name)
  end
end
