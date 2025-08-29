require "test_helper"

class PublicControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_path
    assert_response :redirect
    assert_redirected_to "/#{I18n.default_locale}"
  end
end
