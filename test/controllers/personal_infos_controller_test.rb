require "test_helper"

class PersonalInfosControllerTest < ActionDispatch::IntegrationTest
  test "should get new" do
    get personal_infos_new_url
    assert_response :success
  end

  test "should get create" do
    get personal_infos_create_url
    assert_response :success
  end

  test "should get edit" do
    get personal_infos_edit_url
    assert_response :success
  end

  test "should get update" do
    get personal_infos_update_url
    assert_response :success
  end
end
