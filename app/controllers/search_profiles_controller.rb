# app/controllers/search_profiles_controller.rb
class SearchProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :initialize_search_profile_session, only: [ :step1, :step2, :step3 ]
  before_action :set_search_profile, only: [ :show, :edit, :edit_step1, :edit_step2, :edit_step3, :update, :destroy, :match ]
  before_action :authorize_search_profile_access, only: [ :show, :edit, :edit_step1, :edit_step2, :edit_step3, :update, :destroy ]

  def index
    if current_user.admin?
      @search_profiles = SearchProfile.all.includes(:user, :address)
    else
      @search_profiles = current_user.search_profiles.includes(:address)
    end
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
    search_profile_data = all_data.slice("first_name", "middle_name", "last_name")
    address_data = all_data.slice("country", "state", "city", "neighborhood", "street_address", "postal_code")

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
  def show
    # Display individual search profile
  end

  def edit
    # Redirect to edit step 1 for the multi-step flow
    redirect_to edit_step1_search_profile_path(@search_profile, locale: I18n.locale)
  end

  # Edit Step 1: Basic Information
  def edit_step1
    if request.patch?
      # Handle form submission from edit step 1 (basic info)
      if step1_params.present?
        @search_profile.update!(step1_params)
        redirect_to edit_step2_search_profile_path(@search_profile, locale: I18n.locale)
      else
        @search_profile_data = build_edit_data
        @progress_percentage = 33
        flash.now[:alert] = "Please fill in the required fields."
        render :edit_step1
      end
    else
      # Display edit step 1 form
      @search_profile_data = {
        "first_name" => @search_profile.first_name,
        "middle_name" => @search_profile.middle_name,
        "last_name" => @search_profile.last_name
      }
      @progress_percentage = 33
    end
  end

  # Edit Step 2: Location Information
  def edit_step2
    if request.patch?
      # Handle form submission from edit step 2 (location data)
      if step2_params.present?
        if @search_profile.address
          @search_profile.address.update!(step2_params)
        else
          @search_profile.create_address!(step2_params)
        end
        redirect_to edit_step3_search_profile_path(@search_profile, locale: I18n.locale)
      else
        @search_profile_data = build_edit_data
        @progress_percentage = 67
        flash.now[:alert] = "Please fill in the required fields."
        render :edit_step2
      end
    else
      # Display edit step 2 form
      @search_profile_data = build_edit_data
      @progress_percentage = 67
    end
  end

  # Edit Step 3: Review and Update
  def edit_step3
    # Always display step 3 (review page)
    @search_profile_data = build_edit_data
    @progress_percentage = 100
  end

  def update
    # Final update from edit step 3
    redirect_to search_profiles_path(locale: I18n.locale), notice: "Search profile updated successfully."
  end

  def destroy
    @search_profile.destroy
    redirect_to search_profiles_path(locale: I18n.locale), notice: "Search profile deleted successfully."
  end

  def match
    # Only admins can trigger matches
    unless current_user.admin?
      redirect_to search_profiles_path(locale: I18n.locale), alert: "Only administrators can run matching processes."
      return
    end

    # Start background matching job for better performance
    MatchingJob.perform_later(@search_profile.id)

    redirect_to admin_matches_path(locale: I18n.locale), notice: "Matching process started for #{@search_profile.first_name} #{@search_profile.last_name}. Results will be available shortly."
  end


  private

  def set_search_profile
    @search_profile = SearchProfile.find(params[:id])
  end

  def authorize_search_profile_access
    unless current_user.admin? || @search_profile.user == current_user
      redirect_to search_profiles_path(locale: I18n.locale), alert: "You don't have permission to access this search profile."
    end
  end

  def initialize_search_profile_session
    session[:search_profile_data] ||= {}
  end

  def build_edit_data
    data = {
      "first_name" => @search_profile.first_name,
      "middle_name" => @search_profile.middle_name,
      "last_name" => @search_profile.last_name
    }

    if @search_profile.address
      data.merge!(
        "country" => @search_profile.address.country,
        "state" => @search_profile.address.state,
        "city" => @search_profile.address.city,
        "neighborhood" => @search_profile.address.neighborhood,
        "street_address" => @search_profile.address.street_address,
        "postal_code" => @search_profile.address.postal_code
      )
    end

    data
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
