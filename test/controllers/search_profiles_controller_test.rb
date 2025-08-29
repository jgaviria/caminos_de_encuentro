require "test_helper"

class SearchProfilesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create(:user)
    @search_profile = create(:search_profile, user: @user)
    @other_user = create(:user_with_personal_info)
  end

  test "requires authentication for all actions" do
    get search_profiles_path(locale: I18n.default_locale)
    assert_redirected_to new_user_session_path(locale: I18n.default_locale)

    get new_search_profile_path(locale: I18n.default_locale)
    assert_redirected_to new_user_session_path(locale: I18n.default_locale)

    post match_search_profile_path(@search_profile, locale: I18n.default_locale)
    assert_redirected_to new_user_session_path(locale: I18n.default_locale)
  end

  test "index shows all search profiles" do
    sign_in @user
    get search_profiles_path(locale: I18n.default_locale)

    assert_response :success
    assert_includes assigns(:search_profiles), @search_profile
  end

  test "new initializes search profile for current user" do
    sign_in @user
    get new_search_profile_path(locale: I18n.default_locale)

    assert_response :success
    assert_equal @user, assigns(:search_profile).user
    assert_equal 100, assigns(:progress_percentage)
  end

  test "create saves valid search profile" do
    sign_in @user

    assert_difference "SearchProfile.count", 1 do
      post search_profiles_path(locale: I18n.default_locale), params: {
        search_profile: {
          first_name: "John",
          last_name: "Doe"
        }
      }
    end

    assert_redirected_to dashboard_path(locale: I18n.default_locale)
    assert_equal "Search profile saved successfully.", flash[:notice]
  end

  test "create fails with invalid data" do
    sign_in @user

    assert_no_difference "SearchProfile.count" do
      post search_profiles_path(locale: I18n.default_locale), params: {
        search_profile: {
          first_name: "", # Invalid - required field
          last_name: "Doe"
        }
      }
    end

    assert_response :success # Renders new template
    assert_equal 100, assigns(:progress_percentage)
  end

  test "edit loads user's search profile" do
    sign_in @user
    # Mock current_user.search_profile since it's a singular association
    @user.stubs(:search_profile).returns(@search_profile)

    get edit_search_profile_path(@search_profile, locale: I18n.default_locale)

    assert_response :success
    assert_equal @search_profile, assigns(:search_profile)
    assert_equal 100, assigns(:progress_percentage)
  end

  test "update modifies existing search profile" do
    sign_in @user
    @user.stubs(:search_profile).returns(@search_profile)

    patch search_profile_path(@search_profile, locale: I18n.default_locale), params: {
      search_profile: {
        first_name: "Updated Name",
        last_name: @search_profile.last_name
      }
    }

    @search_profile.reload
    assert_equal "Updated Name", @search_profile.first_name
    assert_redirected_to dashboard_path(locale: I18n.default_locale)
    assert_equal "Search profile updated successfully.", flash[:notice]
  end

  test "update fails with invalid data" do
    sign_in @user
    @user.stubs(:search_profile).returns(@search_profile)
    original_name = @search_profile.first_name

    patch search_profile_path(@search_profile, locale: I18n.default_locale), params: {
      search_profile: {
        first_name: "", # Invalid
        last_name: @search_profile.last_name
      }
    }

    @search_profile.reload
    assert_equal original_name, @search_profile.first_name
    assert_response :success # Renders edit template
    assert_equal 100, assigns(:progress_percentage)
  end

  test "match action enqueues background job" do
    @user.stubs(:admin?).returns(true)
    sign_in @user

    assert_enqueued_with(job: MatchingJob, args: [ @search_profile.id ]) do
      post match_search_profile_path(@search_profile, locale: I18n.default_locale)
    end

    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_match /Matching process started for/, flash[:notice]
  end

  test "match action finds search profile" do
    @user.stubs(:admin?).returns(true)
    sign_in @user

    post match_search_profile_path(@search_profile, locale: I18n.default_locale)

    assert_equal @search_profile, assigns(:profile)
  end

  # Note: Non-existent profile handling is tested in integration tests

  test "search profile params are filtered correctly" do
    sign_in @user

    post search_profiles_path(locale: I18n.default_locale), params: {
      search_profile: {
        first_name: "John",
        middle_name: "Robert",
        last_name: "Doe",
        unauthorized_param: "should be filtered"
      }
    }

    profile = SearchProfile.last
    assert_equal "John", profile.first_name
    assert_equal "Robert", profile.middle_name
    assert_equal "Doe", profile.last_name
    assert_not profile.respond_to?(:unauthorized_param)
  end
end
