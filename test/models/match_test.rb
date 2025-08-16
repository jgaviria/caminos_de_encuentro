require "test_helper"

class MatchTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @search_profile = create(:search_profile)
    @match = create(:match, search_profile: @search_profile, user: @user)
  end

  test "belongs to search profile and user" do
    assert_equal @search_profile, @match.search_profile
    assert_equal @user, @match.user
  end

  test "has valid factory" do
    match = build(:match)
    assert match.valid?
  end

  test "similarity score defaults to 0.0" do
    match = Match.new(search_profile: @search_profile, user: @user)
    assert_equal 0.0, match.similarity_score
  end

  test "is_verified defaults to false" do
    match = Match.new(search_profile: @search_profile, user: @user)
    assert_not match.is_verified
  end

  test "similarity score can be decimal" do
    @match.similarity_score = 0.85
    assert @match.valid?
    @match.save!
    
    @match.reload
    assert_equal 0.85, @match.similarity_score
  end

  test "can be verified" do
    assert_not @match.is_verified
    
    @match.is_verified = true
    @match.save!
    
    @match.reload
    assert @match.is_verified
  end

  test "user association is optional" do
    match = Match.new(search_profile: @search_profile, user: nil)
    assert match.valid?
  end

  test "search profile is required" do
    match = Match.new(user: @user, search_profile: nil)
    assert_not match.valid?
  end

  test "factory traits work correctly" do
    verified_match = create(:match, :verified)
    assert verified_match.is_verified
    
    high_confidence_match = create(:match, :high_confidence)
    assert_equal 0.95, high_confidence_match.similarity_score
    
    exact_match = create(:match, :exact_match)
    assert_equal 1.0, exact_match.similarity_score
  end
end