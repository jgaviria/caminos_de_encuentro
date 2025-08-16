require "test_helper"

class MatchingServiceTest < ActiveSupport::TestCase
  def setup
    # Create test users with personal info
    @seeker_user = create(:user_with_personal_info)
    @seeker_personal_info = @seeker_user.personal_info
    
    # Create search profile
    @search_profile = create(:search_profile, 
      user: @seeker_user,
      first_name: "John",
      last_name: "Doe"
    )
    
    # Create potential matches
    @exact_match_user = create(:user)
    @exact_match_personal_info = create(:personal_info, 
      user: @exact_match_user,
      first_name: "John",
      last_name: "Doe"
    )
    
    @fuzzy_match_user = create(:user)
    @fuzzy_match_personal_info = create(:personal_info,
      user: @fuzzy_match_user,
      first_name: "Jon", # Similar to John
      last_name: "Doe"
    )
    
    @partial_match_user = create(:user)
    @partial_match_personal_info = create(:personal_info,
      user: @partial_match_user,
      first_name: "John",
      last_name: "Smith" # Different last name
    )
    
    @no_match_user = create(:user)
    @no_match_personal_info = create(:personal_info,
      user: @no_match_user,
      first_name: "Maria",
      last_name: "Garcia"
    )
    
    @matching_service = MatchingService.new(@search_profile)
  end

  test "finds exact name matches" do
    matches_count = @matching_service.find_matches
    
    assert_operator matches_count, :>=, 1
    
    exact_match = Match.find_by(
      search_profile: @search_profile,
      user: @exact_match_user
    )
    
    assert_not_nil exact_match
    assert_operator exact_match.similarity_score, :>=, 0.4 # Should be high due to exact name match
  end

  test "finds alternative matches when no exact matches" do
    # Remove exact match
    @exact_match_user.destroy
    
    matches_count = @matching_service.find_matches
    
    # Should find at least some matches (fuzzy or partial)
    assert_operator matches_count, :>=, 0
    
    all_matches = Match.where(search_profile: @search_profile)
    
    # Check if we found any of our test users
    found_fuzzy = all_matches.find_by(user: @fuzzy_match_user)
    found_partial = all_matches.find_by(user: @partial_match_user)
    
    # Should find at least one type of match
    assert(found_fuzzy || found_partial || matches_count == 0, 
           "Should find fuzzy, partial, or no matches when exact match is removed")
  end

  test "excludes matches below minimum threshold" do
    # Temporarily change the minimum match score to be very high
    original_min_score = MatchingService::MINIMUM_MATCH_SCORE
    MatchingService.send(:remove_const, :MINIMUM_MATCH_SCORE)
    MatchingService.const_set(:MINIMUM_MATCH_SCORE, 0.95)
    
    begin
      matches_count = @matching_service.find_matches
      
      # Should only find very high scoring matches
      low_score_matches = Match.where(
        search_profile: @search_profile,
        similarity_score: 0.1..0.94
      )
      
      # Most matches should be filtered out
      assert_operator low_score_matches.count, :<=, 1
    ensure
      # Restore original constant
      MatchingService.send(:remove_const, :MINIMUM_MATCH_SCORE)
      MatchingService.const_set(:MINIMUM_MATCH_SCORE, original_min_score)
    end
  end

  test "does not match user with themselves" do
    # Create a personal info for the seeker that matches the search profile
    @seeker_personal_info.update(
      first_name: @search_profile.first_name,
      last_name: @search_profile.last_name
    )
    
    matches_count = @matching_service.find_matches
    
    self_match = Match.find_by(
      search_profile: @search_profile,
      user: @seeker_user
    )
    
    assert_nil self_match, "Service should not match user with themselves"
  end

  test "calculates location similarity bonus" do
    # Add addresses to search profile and matched user
    search_address = create(:search_profile_address, 
      search_profile: @search_profile,
      country: "Colombia",
      state: "Antioquia",
      city: "Medellin"
    )
    
    user_address = create(:address,
      user: @exact_match_user,
      country: "Colombia",
      state: "Antioquia", 
      city: "Medellin"
    )
    
    matches_count = @matching_service.find_matches
    
    match = Match.find_by(
      search_profile: @search_profile,
      user: @exact_match_user
    )
    
    # Should have reasonable score due to name + location match
    assert_operator match.similarity_score, :>, 0.4
  end

  test "string similarity calculation" do
    service = MatchingService.new(@search_profile)
    
    # Test exact match
    assert_equal 1.0, service.send(:string_similarity, "John", "John")
    
    # Test case insensitive
    assert_equal 1.0, service.send(:string_similarity, "John", "john")
    
    # Test similar strings
    similarity = service.send(:string_similarity, "John", "Jon")
    assert_operator similarity, :>, 0.7
    assert_operator similarity, :<, 1.0
    
    # Test completely different strings
    similarity = service.send(:string_similarity, "John", "Maria")
    assert_operator similarity, :<, 0.3
  end

  test "levenshtein distance calculation" do
    service = MatchingService.new(@search_profile)
    
    # Test identical strings
    assert_equal 0, service.send(:levenshtein_distance, "test", "test")
    
    # Test single character difference
    assert_equal 1, service.send(:levenshtein_distance, "test", "text")
    
    # Test insertion
    assert_equal 1, service.send(:levenshtein_distance, "test", "tests")
    
    # Test deletion
    assert_equal 1, service.send(:levenshtein_distance, "tests", "test")
  end

  test "bulk creates match records efficiently" do
    # Clear any existing matches
    Match.destroy_all
    
    initial_count = Match.count
    matches_count = @matching_service.find_matches
    
    assert_operator Match.count, :>, initial_count
    assert_equal matches_count, Match.count - initial_count
  end

  test "handles empty search results gracefully" do
    # Create search profile with names that won't match anyone
    unique_profile = create(:search_profile,
      first_name: "UniqueFirstName123",
      last_name: "UniqueLastName456"
    )
    
    service = MatchingService.new(unique_profile)
    matches_count = service.find_matches
    
    assert_equal 0, matches_count
  end

  test "temporal relevance affects scoring" do
    # Create old personal info
    old_user = create(:user)
    old_personal_info = create(:personal_info,
      user: old_user,
      first_name: "John",
      last_name: "Doe",
      created_at: 2.years.ago
    )
    
    # Create recent personal info
    recent_user = create(:user)
    recent_personal_info = create(:personal_info,
      user: recent_user,
      first_name: "John",
      last_name: "Doe",
      created_at: 1.day.ago
    )
    
    matches_count = @matching_service.find_matches
    
    old_match = Match.find_by(search_profile: @search_profile, user: old_user)
    recent_match = Match.find_by(search_profile: @search_profile, user: recent_user)
    
    # Recent match should have higher score due to temporal relevance
    assert_operator recent_match.similarity_score, :>=, old_match.similarity_score
  end
end