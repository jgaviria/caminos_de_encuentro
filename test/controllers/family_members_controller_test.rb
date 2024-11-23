require "test_helper"

class FamilyMembersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @family_member = family_members(:one)
  end

  test "should get index" do
    get family_members_url
    assert_response :success
  end

  test "should get new" do
    get new_family_member_url
    assert_response :success
  end

  test "should create family_member" do
    assert_difference("FamilyMember.count") do
      post family_members_url, params: { family_member: { first_name: @family_member.first_name, last_name: @family_member.last_name, profile_id: @family_member.profile_id, relationship: @family_member.relationship } }
    end

    assert_redirected_to family_member_url(FamilyMember.last)
  end

  test "should show family_member" do
    get family_member_url(@family_member)
    assert_response :success
  end

  test "should get edit" do
    get edit_family_member_url(@family_member)
    assert_response :success
  end

  test "should update family_member" do
    patch family_member_url(@family_member), params: { family_member: { first_name: @family_member.first_name, last_name: @family_member.last_name, profile_id: @family_member.profile_id, relationship: @family_member.relationship } }
    assert_redirected_to family_member_url(@family_member)
  end

  test "should destroy family_member" do
    assert_difference("FamilyMember.count", -1) do
      delete family_member_url(@family_member)
    end

    assert_redirected_to family_members_url
  end
end
