require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  def setup
    @user = create(:user)
  end
  test "should get show" do
    sign_in @user
    get dashboard_path(locale: I18n.default_locale)
    assert_response :success
  end
end
