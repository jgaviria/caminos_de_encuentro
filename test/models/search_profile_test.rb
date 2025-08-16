require "test_helper"

class SearchProfileTest < ActiveSupport::TestCase
  def setup
    @user = create(:user)
    @search_profile = create(:search_profile, user: @user)
  end

  test "belongs to user" do
    assert_equal @user, @search_profile.user
  end

  test "has many matches" do
    match1 = create(:match, search_profile: @search_profile)
    match2 = create(:match, search_profile: @search_profile)
    
    assert_includes @search_profile.matches, match1
    assert_includes @search_profile.matches, match2
  end

  test "has one address" do
    address = create(:search_profile_address, search_profile: @search_profile)
    assert_equal address, @search_profile.address
  end

  test "validates presence of first_name and last_name" do
    profile = SearchProfile.new(user: @user)
    assert_not profile.valid?
    
    profile.first_name = "John"
    assert_not profile.valid?
    
    profile.last_name = "Doe"
    assert profile.valid?
  end

  test "destroys dependent matches when deleted" do
    match = create(:match, search_profile: @search_profile)
    match_id = match.id
    
    @search_profile.destroy
    
    assert_not Match.exists?(match_id)
  end

  test "destroys dependent address when deleted" do
    address = create(:search_profile_address, search_profile: @search_profile)
    address_id = address.id
    
    @search_profile.destroy
    
    assert_not Address.exists?(address_id)
  end

  test "factory creates valid search profile" do
    profile = build(:search_profile)
    assert profile.valid?
  end

  test "factory traits work correctly" do
    maria_profile = create(:search_profile, :maria)
    assert_equal "Maria", maria_profile.first_name
    assert_equal "Garcia", maria_profile.last_name
    
    carlos_profile = create(:search_profile, :carlos)
    assert_equal "Carlos", carlos_profile.first_name
    assert_equal "Rodriguez", carlos_profile.last_name
  end

  test "complete search profile factory includes address" do
    complete_profile = create(:complete_search_profile)
    assert_not_nil complete_profile.address
  end
end