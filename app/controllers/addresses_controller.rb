# app/controllers/addresses_controller.rb
class AddressesController < ApplicationController
  before_action :authenticate_user!

  def new
    @address = current_user.build_address
    @progress_percentage = 66
  end

  def create
    @address = current_user.build_address(address_params)
    if @address.save
      redirect_to new_search_profile_path, notice: "Address saved successfully."
    else
      @progress_percentage = 66
      render :new
    end
  end

  def edit
    @address = current_user.address
    @progress_percentage = 66
  end

  def update
    @address = current_user.address
    if @address.update(address_params)
      redirect_to dashboard_path, notice: "Address updated successfully."
    else
      @progress_percentage = 66
      render :edit
    end
  end

  private

  def address_params
    params.require(:address).permit(:country, :state, :city, :neighborhood, :street_address, :postal_code)
  end
end
