require "test_helper"

class BatchMatchingJobTest < ActiveJob::TestCase
  def setup
    # Create search profiles without matches
    @profile1 = create(:search_profile)
    @profile2 = create(:search_profile)
    @profile3 = create(:search_profile)

    # Create a search profile with recent matches
    @profile_with_matches = create(:search_profile)
    create(:match, search_profile: @profile_with_matches, created_at: 1.day.ago)

    # Create a search profile with old matches
    @profile_with_old_matches = create(:search_profile)
    create(:match, search_profile: @profile_with_old_matches, created_at: 2.weeks.ago)
  end

  test "enqueues matching jobs for profiles without matches" do
    assert_enqueued_jobs 0

    BatchMatchingJob.perform_now

    # Should enqueue jobs for profiles without matches + profile with old matches
    assert_enqueued_jobs 4 # profile1, profile2, profile3, profile_with_old_matches
  end

  test "respects batch size parameter" do
    # Create additional profiles
    create_list(:search_profile, 5)

    assert_enqueued_jobs 0

    BatchMatchingJob.perform_now(batch_size: 3)

    # Should only enqueue 3 jobs due to batch size limit
    assert_enqueued_jobs 3
  end

  test "excludes profiles with recent matches" do
    clear_enqueued_jobs

    BatchMatchingJob.perform_now

    # Should not enqueue job for profile_with_matches (has recent matches)
    matching_jobs = enqueued_jobs.select { |job| job[:job] == MatchingJob }
    profile_ids = matching_jobs.map { |job| job[:args].first }

    assert_not_includes profile_ids, @profile_with_matches.id
  end

  test "includes profiles with old matches" do
    clear_enqueued_jobs

    BatchMatchingJob.perform_now

    # Should enqueue job for profile_with_old_matches (has old matches)
    matching_jobs = enqueued_jobs.select { |job| job[:job] == MatchingJob }
    profile_ids = matching_jobs.map { |job| job[:args].first }

    assert_includes profile_ids, @profile_with_old_matches.id
  end

  test "handles empty database gracefully" do
    SearchProfile.destroy_all

    assert_nothing_raised do
      BatchMatchingJob.perform_now
    end

    assert_enqueued_jobs 0
  end

  test "logs batch processing information" do
    # This test verifies the job runs without errors
    # In a real application, you might want to test actual log output
    assert_nothing_raised do
      BatchMatchingJob.perform_now
    end
  end

  test "uses default batch size when not specified" do
    # Clear existing profiles and create exactly 12 profiles
    SearchProfile.destroy_all
    create_list(:search_profile, 12)

    clear_enqueued_jobs

    BatchMatchingJob.perform_now # Should use default batch_size: 10

    # Should only process 10 profiles due to default batch size
    assert_enqueued_jobs 10
  end

  test "finds profiles with no matches using left join" do
    # This test ensures the SQL query logic is correct
    profiles_to_match = SearchProfile.left_joins(:matches)
                                     .where(matches: { id: nil })
                                     .or(SearchProfile.left_joins(:matches)
                                                      .where("matches.created_at < ?", 1.week.ago))
                                     .distinct

    # Should include profiles without matches and those with old matches
    expected_profiles = [ @profile1, @profile2, @profile3, @profile_with_old_matches ]

    assert_equal expected_profiles.size, profiles_to_match.count
    expected_profiles.each do |profile|
      assert_includes profiles_to_match, profile
    end

    # Should not include profile with recent matches
    assert_not_includes profiles_to_match, @profile_with_matches
  end
end
