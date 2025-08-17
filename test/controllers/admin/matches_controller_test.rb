require "test_helper"

class Admin::MatchesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers
  
  def setup
    @admin_user = create(:user) # Will need admin functionality
    @regular_user = create(:user)
    
    @search_profile = create(:search_profile, user: @regular_user)
    @matched_user = create(:user_with_personal_info)
    
    @verified_match = create(:match, :verified,
      search_profile: @search_profile,
      user: @matched_user,
      similarity_score: 0.9
    )
    
    @unverified_match = create(:match,
      search_profile: @search_profile, 
      user: create(:user),
      similarity_score: 0.7
    )
    
    @high_confidence_match = create(:match, :high_confidence,
      search_profile: create(:search_profile),
      user: create(:user)
    )
  end

  test "requires admin authentication" do
    get admin_matches_path(locale: I18n.default_locale)
    assert_redirected_to new_user_session_path(locale: I18n.default_locale)
  end

  test "redirects non-admin users" do
    sign_in @regular_user
    get admin_matches_path(locale: I18n.default_locale)
    
    assert_redirected_to root_path(locale: I18n.default_locale)
    assert_equal "Access denied. Admin privileges required.", flash[:alert]
  end

  test "admin can access index" do
    # Mock admin functionality since it's not fully implemented
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_matches_path(locale: I18n.default_locale)
    assert_response :success
  end

  test "index shows all matches with statistics" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_matches_path(locale: I18n.default_locale)
    
    assert_response :success
    matches = assigns(:matches)
    stats = assigns(:stats)
    
    assert_includes matches, @verified_match
    assert_includes matches, @unverified_match
    assert_includes matches, @high_confidence_match
    
    assert_kind_of Hash, stats
    assert_includes stats.keys, :total_matches
    assert_includes stats.keys, :verified_matches
    assert_includes stats.keys, :pending_matches
    assert_includes stats.keys, :high_confidence_matches
    assert_includes stats.keys, :recent_matches
  end

  test "index filters by verification status" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_matches_path(locale: I18n.default_locale), params: { verified: "true" }
    
    matches = assigns(:matches)
    assert_includes matches, @verified_match
    assert_not_includes matches, @unverified_match
  end

  test "index filters by minimum score" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_matches_path(locale: I18n.default_locale), params: { min_score: "0.8" }
    
    matches = assigns(:matches)
    assert_includes matches, @verified_match # score 0.9
    assert_includes matches, @high_confidence_match # score 0.95
    assert_not_includes matches, @unverified_match # score 0.7
  end

  test "show displays match details" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_match_path(@verified_match, locale: I18n.default_locale)
    
    assert_response :success
    assert_equal @verified_match, assigns(:match)
    assert_equal @search_profile, assigns(:search_profile)
    assert_equal @matched_user, assigns(:matched_user)
  end

  test "verify marks match as verified" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    assert_not @unverified_match.is_verified
    
    patch verify_admin_match_path(@unverified_match, locale: I18n.default_locale)
    
    @unverified_match.reload
    assert @unverified_match.is_verified
    assert_redirected_to admin_match_path(@unverified_match, locale: I18n.default_locale)
    assert_equal "Match verified successfully.", flash[:notice]
  end

  test "reject destroys match" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    assert_difference "Match.count", -1 do
      delete reject_admin_match_path(@unverified_match, locale: I18n.default_locale)
    end
    
    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_equal "Match rejected and removed.", flash[:notice]
  end

  test "bulk_verify updates multiple matches" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    match1 = create(:match, is_verified: false)
    match2 = create(:match, is_verified: false)
    
    post bulk_verify_admin_matches_path(locale: I18n.default_locale), params: {
      match_ids: [match1.id, match2.id]
    }
    
    match1.reload
    match2.reload
    
    assert match1.is_verified
    assert match2.is_verified
    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_equal "2 matches verified.", flash[:notice]
  end

  test "bulk_reject destroys multiple matches" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    match1 = create(:match)
    match2 = create(:match)
    
    assert_difference "Match.count", -2 do
      post bulk_reject_admin_matches_path(locale: I18n.default_locale), params: {
        match_ids: [match1.id, match2.id]
      }
    end
    
    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_equal "2 matches rejected.", flash[:notice]
  end

  test "bulk operations handle empty match_ids" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    # Clear any existing data to ensure clean test
    Match.destroy_all
    
    post bulk_verify_admin_matches_path(locale: I18n.default_locale), params: { match_ids: [] }
    
    assert_redirected_to admin_matches_path(locale: I18n.default_locale)
    assert_equal "0 matches verified.", flash[:notice]
  end

  test "export generates CSV" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get export_admin_matches_path(locale: I18n.default_locale), params: { format: :csv }
    
    assert_response :success
    assert_equal "text/csv", response.content_type
    assert_match /attachment; filename="matches_export_/, response.headers["Content-Disposition"]
  end

  test "CSV export contains proper headers" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get export_admin_matches_path(locale: I18n.default_locale), params: { format: :csv }
    
    csv_content = response.body
    headers = csv_content.lines.first.strip.split(",")
    
    expected_headers = [
      "Match ID", "Search Profile ID", "Seeker Name", "Seeker Email",
      "Matched User ID", "Matched Name", "Matched Email",
      "Similarity Score", "Verified", "Created At"
    ]
    
    assert_equal expected_headers, headers
  end

  test "statistics calculation is accurate" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    # Clear existing matches to have predictable counts
    Match.destroy_all
    
    # Create test matches
    create(:match, :verified)
    create(:match, :verified)
    create(:match) # unverified
    create(:match, :high_confidence) # score >= 0.8
    create(:match, created_at: 2.days.ago) # recent
    
    get admin_matches_path(locale: I18n.default_locale)
    
    stats = assigns(:stats)
    
    assert_equal 5, stats[:total_matches]
    assert_equal 2, stats[:verified_matches]
    assert_equal 3, stats[:pending_matches]
    assert_equal 5, stats[:high_confidence_matches] # All matches have score >= 0.8
    assert_equal 5, stats[:recent_matches] # all created within a week
  end

  test "pagination works correctly" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    # Create many matches
    create_list(:match, 25)
    
    get admin_matches_path(locale: I18n.default_locale)
    
    matches = assigns(:matches)
    
    # Should paginate (20 per page by default)
    assert_equal 20, matches.count
  end

  test "matches are ordered by similarity score and creation date" do
    @admin_user.stubs(:admin?).returns(true)
    sign_in @admin_user
    
    get admin_matches_path(locale: I18n.default_locale)
    
    matches = assigns(:matches).to_a
    
    # Verify ordering
    (0...matches.length - 1).each do |i|
      current = matches[i]
      next_match = matches[i + 1]
      
      # Higher score comes first, or if scores equal, newer comes first
      assert(
        current.similarity_score > next_match.similarity_score ||
        (current.similarity_score == next_match.similarity_score && 
         current.created_at >= next_match.created_at)
      )
    end
  end
end