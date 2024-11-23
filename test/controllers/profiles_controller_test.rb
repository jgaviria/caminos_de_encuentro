require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @profile = profiles(:one)
  end

  test "should get index" do
    get profiles_url
    assert_response :success
  end

  test "should get new" do
    get new_profile_url
    assert_response :success
  end

  test "should create profile" do
    assert_difference("Profile.count") do
      post profiles_url, params: { profile: { city_of_birth: @profile.city_of_birth, country_of_birth: @profile.country_of_birth, dob: @profile.dob, father_name: @profile.father_name, first_name: @profile.first_name, last_known_city: @profile.last_known_city, last_known_neighborhood: @profile.last_known_neighborhood, last_name: @profile.last_name, mother_name: @profile.mother_name, status: @profile.status, user_id: @profile.user_id } }
    end

    assert_redirected_to profile_url(Profile.last)
  end

  test "should show profile" do
    get profile_url(@profile)
    assert_response :success
  end

  test "should get edit" do
    get edit_profile_url(@profile)
    assert_response :success
  end

  test "should update profile" do
    patch profile_url(@profile), params: { profile: { city_of_birth: @profile.city_of_birth, country_of_birth: @profile.country_of_birth, dob: @profile.dob, father_name: @profile.father_name, first_name: @profile.first_name, last_known_city: @profile.last_known_city, last_known_neighborhood: @profile.last_known_neighborhood, last_name: @profile.last_name, mother_name: @profile.mother_name, status: @profile.status, user_id: @profile.user_id } }
    assert_redirected_to profile_url(@profile)
  end

  test "should destroy profile" do
    assert_difference("Profile.count", -1) do
      delete profile_url(@profile)
    end

    assert_redirected_to profiles_url
  end
end
