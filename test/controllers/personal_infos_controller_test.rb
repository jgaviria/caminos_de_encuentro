require "test_helper"

class PersonalInfosControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create(:user)
    @personal_info = create(:personal_info, user: @user)
  end
  test "should get new" do
    sign_in @user
    get new_personal_info_path(locale: I18n.default_locale)
    assert_response :success
  end

  test "should get create" do
    sign_in @user
    post personal_info_path(locale: I18n.default_locale), params: {
      personal_info: {
        first_name: "John",
        last_name: "Doe"
      }
    }
    assert_redirected_to new_address_path(locale: I18n.default_locale)
  end

  test "should get edit" do
    sign_in @user
    get edit_personal_info_path(locale: I18n.default_locale)
    assert_response :success
  end

  test "should get update" do
    sign_in @user
    patch personal_info_path(locale: I18n.default_locale), params: {
      personal_info: {
        first_name: "Jane",
        last_name: "Smith"
      }
    }
    assert_redirected_to edit_address_path(locale: I18n.default_locale)
  end
end
