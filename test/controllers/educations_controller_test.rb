require "test_helper"

class EducationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @education = educations(:one)
  end

  test "should get index" do
    get educations_url
    assert_response :success
  end

  test "should get new" do
    get new_education_url
    assert_response :success
  end

  test "should create education" do
    assert_difference("Education.count") do
      post educations_url, params: { education: { date_from: @education.date_from, date_to: @education.date_to, level: @education.level, profile_id: @education.profile_id, school_name: @education.school_name } }
    end

    assert_redirected_to education_url(Education.last)
  end

  test "should show education" do
    get education_url(@education)
    assert_response :success
  end

  test "should get edit" do
    get edit_education_url(@education)
    assert_response :success
  end

  test "should update education" do
    patch education_url(@education), params: { education: { date_from: @education.date_from, date_to: @education.date_to, level: @education.level, profile_id: @education.profile_id, school_name: @education.school_name } }
    assert_redirected_to education_url(@education)
  end

  test "should destroy education" do
    assert_difference("Education.count", -1) do
      delete education_url(@education)
    end

    assert_redirected_to educations_url
  end
end
