# app/controllers/personal_infos_controller.rb
class PersonalInfosController < ApplicationController
  before_action :authenticate_user!

  def new
    @personal_info = current_user.build_personal_info
    @progress_percentage = 33
  end

  def create
    @personal_info = current_user.build_personal_info(personal_info_params)
    if @personal_info.save
      redirect_to new_address_path, notice: 'Personal information saved successfully.'
    else
      @progress_percentage = 33
      render :new
    end
  end

  def edit
    @personal_info = current_user.personal_info
    @progress_percentage = 33
  end

  def update
    @personal_info = current_user.personal_info
    if @personal_info.update(personal_info_params)
      redirect_to edit_address_path, notice: 'Personal information updated successfully.'
    else
      @progress_percentage = 33
      render :edit
    end
  end

  private

  def personal_info_params
    params.require(:personal_info).permit(:first_name, :middle_name, :last_name, :phone_number)
  end
end
