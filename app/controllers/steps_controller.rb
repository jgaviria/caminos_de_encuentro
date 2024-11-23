class StepsController < ApplicationController
  before_action :set_user

  def show
    @step = params[:id]
    case @step
    when "profile"
      @profile = @user.profiles.build
    when "address"
      @address = @user.profiles.last.addresses.build
    when "family_member"
      @family_member = @user.profiles.last.family_members.build
    when "education"
      @education = @user.profiles.last.educations.build
    end
  end

  def update
    @step = params[:id]
    case @step
    when "profile"
      @profile = @user.profiles.create(profile_params)
      redirect_to step_path("address")
    when "address"
      @address = @user.profiles.last.addresses.create(address_params)
      redirect_to step_path("family_member")
    when "family_member"
      @family_member = @user.profiles.last.family_members.create(family_member_params)
      redirect_to step_path("education")
    when "education"
      @education = @user.profiles.last.educations.create(education_params)
      redirect_to root_path, notice: "All steps completed!"
    end
  end

  private

  def set_user
    @user = current_user
  end

  def profile_params
    params.require(:profile).permit(:first_name, :last_name, :dob, :city_of_birth, :country_of_birth, :mother_name, :father_name, :last_known_city, :last_known_neighborhood, :status)
  end

  def address_params
    params.require(:address).permit(:address_line, :city, :country, :date_from, :date_to)
  end

  def family_member_params
    params.require(:family_member).permit(:relationship, :first_name, :last_name)
  end

  def education_params
    params.require(:education).permit(:school_name, :level, :date_from, :date_to)
  end
end
