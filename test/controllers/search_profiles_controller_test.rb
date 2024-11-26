require "test_helper"

class SearchProfilesControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get search_profiles_new_url
    assert_response :success
  end

  test "should get create" do
    get search_profiles_create_url
    assert_response :success
  end

  test "should get edit" do
    get search_profiles_edit_url
    assert_response :success
  end

  test "should get update" do
    get search_profiles_update_url
    assert_response :success
  end
end
