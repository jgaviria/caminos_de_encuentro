require "test_helper"

class AddressesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  def setup
    @user = create(:user)
    @address = create(:address, user: @user)
  end
  test "should get new" do
    sign_in @user
    get new_address_path(locale: I18n.default_locale)
    assert_response :success
  end

  test "should get create" do
    sign_in @user
    post address_path(locale: I18n.default_locale), params: { 
      address: { 
        street: "123 Main St", 
        city: "Test City", 
        state: "Test State", 
        country: "Test Country" 
      } 
    }
    assert_redirected_to new_search_profile_path(locale: I18n.default_locale)
  end

  test "should get edit" do
    sign_in @user
    get edit_address_path(locale: I18n.default_locale)
    assert_response :success
  end

  test "should get update" do
    sign_in @user
    patch address_path(locale: I18n.default_locale), params: { 
      address: { 
        street: "456 Updated St", 
        city: "Updated City", 
        state: "Updated State", 
        country: "Updated Country" 
      } 
    }
    assert_redirected_to edit_search_profile_path(locale: I18n.default_locale)
  end
end
