require "test_helper"

class MatchesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = create(:user_with_personal_info)
    @other_user = create(:user_with_personal_info)

    # Create search profile for user
    @search_profile = create(:search_profile, user: @user)

    # Create matches where user is the seeker
    @user_search_match = create(:match,
      search_profile: @search_profile,
      user: @other_user
    )

    # Create match where user is the matched person
    @other_search_profile = create(:search_profile, user: @other_user)
    @user_profile_match = create(:match,
      search_profile: @other_search_profile,
      user: @user
    )

    # Create match that user shouldn't see
    @unrelated_user = create(:user)
    @unrelated_search_profile = create(:search_profile, user: @unrelated_user)
    @unrelated_match = create(:match,
      search_profile: @unrelated_search_profile,
      user: create(:user)
    )
  end

  test "requires authentication for index" do
    get matches_path(locale: I18n.default_locale)
    assert_redirected_to new_user_session_path(locale: I18n.default_locale)
  end

  test "index shows user's relevant matches" do
    sign_in @user
    get matches_path(locale: I18n.default_locale)

    assert_response :success
    assert_includes assigns(:matches), @user_search_match
    assert_includes assigns(:matches), @user_profile_match
    assert_not_includes assigns(:matches), @unrelated_match
  end

  test "index handles empty matches gracefully" do
    user_without_matches = create(:user)
    sign_in user_without_matches

    get matches_path(locale: I18n.default_locale)

    assert_response :success
    assert_empty assigns(:matches)
  end

  test "show displays match details when user has permission" do
    sign_in @user
    get match_path(@user_search_match, locale: I18n.default_locale)

    assert_response :success
    assert_equal @user_search_match, assigns(:match)
  end

  test "show redirects when user lacks permission" do
    sign_in @user
    get match_path(@unrelated_match, locale: I18n.default_locale)

    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "You don't have permission to view this match.", flash[:alert]
  end

  test "verify updates match when user has permission" do
    sign_in @user

    assert_not @user_search_match.is_verified

    patch verify_match_path(@user_search_match, locale: I18n.default_locale)

    @user_search_match.reload
    assert @user_search_match.is_verified
    assert_redirected_to match_path(@user_search_match, locale: I18n.default_locale)
    assert_equal "Match has been verified.", flash[:notice]
  end

  test "verify fails when user lacks permission" do
    sign_in @user

    patch verify_match_path(@unrelated_match, locale: I18n.default_locale)

    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "You don't have permission to verify this match.", flash[:alert]
  end

  test "destroy removes match when user has permission" do
    sign_in @user

    assert_difference "Match.count", -1 do
      delete match_path(@user_search_match, locale: I18n.default_locale)
    end

    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "Match has been removed.", flash[:notice]
  end

  test "destroy fails when user lacks permission" do
    sign_in @user

    assert_no_difference "Match.count" do
      delete match_path(@unrelated_match, locale: I18n.default_locale)
    end

    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "You don't have permission to remove this match.", flash[:alert]
  end

  test "can_view_match allows search profile owner" do
    sign_in @user
    get match_path(@user_search_match, locale: I18n.default_locale)

    assert_response :success
  end

  test "can_view_match allows matched user" do
    sign_in @user
    get match_path(@user_profile_match, locale: I18n.default_locale)

    assert_response :success
  end

  test "combines search profile matches and user profile matches" do
    sign_in @user
    get matches_path(locale: I18n.default_locale)

    matches = assigns(:matches)

    # Should include both types of matches
    assert_includes matches, @user_search_match
    assert_includes matches, @user_profile_match

    # Should be sorted by similarity score and creation date
    assert_equal matches, matches.sort_by { |m| [ -m.similarity_score, -m.created_at.to_i ] }
  end

  test "removes duplicate matches from combined results" do
    # Create a scenario where a match could appear in both queries
    # This is theoretically possible if there are database inconsistencies
    sign_in @user
    get matches_path(locale: I18n.default_locale)

    matches = assigns(:matches)
    match_ids = matches.map(&:id)

    # Should not have duplicate IDs
    assert_equal match_ids.uniq.size, match_ids.size
  end

  test "handles user with admin privileges for verification" do
    # This test assumes admin functionality is implemented
    # admin_user = create(:user, :admin)
    # sign_in admin_user
    #
    # patch verify_match_path(@unrelated_match)
    #
    # @unrelated_match.reload
    # assert @unrelated_match.is_verified
    skip "Admin functionality not yet implemented"
  end
end
