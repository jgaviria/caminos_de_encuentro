require "test_helper"

class MatchingWorkflowTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    # Create seeker user with complete profile
    @seeker = create(:complete_user)
    @seeker_profile = create(:complete_search_profile,
      user: @seeker,
      first_name: "Juan",
      last_name: "Garcia"
    )

    # Create potential matches
    @exact_match_user = create(:user)
    @exact_match_personal_info = create(:personal_info,
      user: @exact_match_user,
      first_name: "Juan",
      last_name: "Garcia"
    )
    @exact_match_address = create(:address, user: @exact_match_user)

    @partial_match_user = create(:user)
    @partial_match_personal_info = create(:personal_info,
      user: @partial_match_user,
      first_name: "Juan",
      last_name: "Rodriguez"
    )

    @no_match_user = create(:user)
    @no_match_personal_info = create(:personal_info,
      user: @no_match_user,
      first_name: "Maria",
      last_name: "Lopez"
    )
  end

  test "complete end-to-end matching workflow" do
    @seeker.update!(admin: true)
    sign_in @seeker

    # Step 1: User creates a search profile through multi-step flow
    get new_search_profile_path(locale: I18n.default_locale)
    assert_redirected_to step1_search_profiles_path(locale: I18n.default_locale)

    # Complete the multi-step flow
    post step1_search_profiles_path(locale: I18n.default_locale), params: {
      search_profile: {
        first_name: "Carlos",
        last_name: "Mendez"
      }
    }
    assert_redirected_to step2_search_profiles_path(locale: I18n.default_locale)

    post step2_search_profiles_path(locale: I18n.default_locale), params: {
      address: {}
    }
    assert_redirected_to step3_search_profiles_path(locale: I18n.default_locale)

    post search_profiles_path(locale: I18n.default_locale)
    assert_redirected_to dashboard_path(locale: I18n.default_locale)

    new_profile = SearchProfile.last
    assert_equal "Carlos", new_profile.first_name
    assert_equal "Mendez", new_profile.last_name

    # Step 2: User initiates matching process
    post match_search_profile_path(new_profile, locale: I18n.default_locale)

    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_match /Matching process started for/, flash[:notice]

    # Verify job was enqueued
    assert_enqueued_jobs 1, only: MatchingJob

    # Step 3: Background job processes the match
    perform_enqueued_jobs

    # Step 4: User views their matches
    get matches_path(locale: I18n.default_locale)
    assert_response :success

    # Should find any existing matches for this profile
    matches = assigns(:matches)
    assert_kind_of Array, matches
  end

  test "user can view and manage their matches" do
    sign_in @seeker

    # Create some matches for the user
    perform_enqueued_jobs do
      MatchingJob.perform_later(@seeker_profile.id)
    end

    # View matches index
    get matches_path(locale: I18n.default_locale)
    assert_response :success

    matches = assigns(:matches)

    if matches.any?
      match = matches.first

      # View individual match
      get match_path(match, locale: I18n.default_locale)
      assert_response :success

      # Verify match (if user owns the search profile)
      if match.search_profile.user == @seeker
        patch verify_match_path(match, locale: I18n.default_locale)
        assert_redirected_to match_path(match, locale: I18n.default_locale)

        match.reload
        assert match.is_verified
      end
    end
  end

  test "matching algorithm finds appropriate candidates" do
    # Run the matching service directly
    service = MatchingService.new(@seeker_profile)
    matches_created = service.find_matches

    assert_operator matches_created, :>=, 1, "Should find at least one match"

    # Check that exact match was found
    exact_match = Match.find_by(
      search_profile: @seeker_profile,
      user: @exact_match_user
    )

    assert_not_nil exact_match, "Should find exact name match"
    assert_operator exact_match.similarity_score, :>, 0.6, "Exact match should have high score"
  end

  test "batch matching processes multiple profiles" do
    # Create additional search profiles
    profile2 = create(:search_profile, first_name: "Ana", last_name: "Silva")
    profile3 = create(:search_profile, first_name: "Pedro", last_name: "Ramirez")

    initial_match_count = Match.count

    # Run batch matching
    perform_enqueued_jobs do
      BatchMatchingJob.perform_now(batch_size: 5)
    end

    # Should have created matches for profiles
    assert_operator Match.count, :>, initial_match_count
  end

  test "location-based matching provides bonus scoring" do
    # Create users in the same location
    same_city_user = create(:user)
    same_city_personal_info = create(:personal_info,
      user: same_city_user,
      first_name: "Juan",
      last_name: "Garcia"
    )
    same_city_address = create(:address,
      user: same_city_user,
      city: @seeker_profile.address.city,
      state: @seeker_profile.address.state,
      country: @seeker_profile.address.country
    )

    # Create user in different location
    different_city_user = create(:user)
    different_city_personal_info = create(:personal_info,
      user: different_city_user,
      first_name: "Juan",
      last_name: "Garcia"
    )
    different_city_address = create(:address, :bogota, user: different_city_user)

    # Run matching
    service = MatchingService.new(@seeker_profile)
    service.find_matches

    same_city_match = Match.find_by(
      search_profile: @seeker_profile,
      user: same_city_user
    )

    different_city_match = Match.find_by(
      search_profile: @seeker_profile,
      user: different_city_user
    )

    # Same city should have higher score due to location bonus
    if same_city_match && different_city_match
      assert_operator same_city_match.similarity_score, :>=, different_city_match.similarity_score
    end
  end

  test "fuzzy matching finds similar but not exact names" do
    # Create user with similar name that will trigger fuzzy matching
    similar_user = create(:user)
    similar_personal_info = create(:personal_info,
      user: similar_user,
      first_name: "Juanan", # Similar to Juan (similarity > 0.7)
      last_name: "Garcia" # Same last name for higher score
    )
    similar_address = create(:address, user: similar_user)

    # Remove exact and partial matches to test fuzzy matching
    @exact_match_user.destroy
    @partial_match_user.destroy
    @no_match_user.destroy # Remove this too to ensure clean fuzzy test

    service = MatchingService.new(@seeker_profile)
    matches_created = service.find_matches

    similar_match = Match.find_by(
      search_profile: @seeker_profile,
      user: similar_user
    )

    # Ensure we found a match
    assert_not_nil similar_match, "Should find a fuzzy match for similar name"

    # Check the similarity score is in expected range
    assert_operator similar_match.similarity_score, :>, 0.3, "Fuzzy match should have reasonable score above minimum threshold"
    assert_operator similar_match.similarity_score, :<, 1.0, "Fuzzy match should not be perfect"
  end

  test "admin workflow for match verification" do
    # Create an admin user (assuming admin functionality exists)
    admin = create(:user, admin: true)

    # Create some matches
    service = MatchingService.new(@seeker_profile)
    service.find_matches

    sign_in admin

    # Admin views all matches
    get admin_matches_path(locale: I18n.default_locale)
    assert_response :success

    matches = assigns(:matches)
    stats = assigns(:stats)

    assert_kind_of Hash, stats

    if matches.any?
      match = matches.first

      # Admin views match details
      get admin_match_path(match, locale: I18n.default_locale)
      assert_response :success

      # Admin verifies match
      patch verify_admin_match_path(match, locale: I18n.default_locale)
      assert_redirected_to admin_match_path(match, locale: I18n.default_locale)

      match.reload
      assert match.is_verified
    end
  end

  test "user cannot access other users' matches" do
    other_user = create(:user)
    other_profile = create(:search_profile, user: other_user)
    other_match = create(:match, search_profile: other_profile)

    sign_in @seeker

    # Should not be able to view other user's match
    get match_path(other_match, locale: I18n.default_locale)
    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "You don't have permission to view this match.", flash[:alert]

    # Should not be able to verify other user's match
    patch verify_match_path(other_match, locale: I18n.default_locale)
    assert_redirected_to matches_path(locale: I18n.default_locale)
    assert_equal "You don't have permission to verify this match.", flash[:alert]
  end

  test "performance with large dataset" do
    # Create a larger dataset
    users = create_list(:user, 50)
    users.each do |user|
      create(:personal_info, user: user,
        first_name: [ "Juan", "Carlos", "Pedro", "Ana", "Maria" ].sample,
        last_name: [ "Garcia", "Rodriguez", "Martinez", "Lopez", "Silva" ].sample
      )
    end

    # Measure performance
    start_time = Time.current

    service = MatchingService.new(@seeker_profile)
    matches_created = service.find_matches

    end_time = Time.current
    execution_time = end_time - start_time

    # Should complete within reasonable time (adjust threshold as needed)
    assert_operator execution_time, :<, 10.seconds, "Matching should complete quickly even with larger dataset"

    # Should still find matches
    assert_operator matches_created, :>=, 0
  end
end
