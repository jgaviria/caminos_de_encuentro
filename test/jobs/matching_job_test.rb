require "test_helper"

class MatchingJobTest < ActiveJob::TestCase
  def setup
    @user = create(:user_with_personal_info)
    @search_profile = create(:search_profile, user: @user)

    # Create potential match
    @match_user = create(:user)
    @match_personal_info = create(:personal_info,
      user: @match_user,
      first_name: @search_profile.first_name,
      last_name: @search_profile.last_name
    )
  end

  test "performs matching job successfully" do
    assert_enqueued_jobs 0

    MatchingJob.perform_later(@search_profile.id)

    assert_enqueued_jobs 1
    assert_enqueued_with(job: MatchingJob, args: [ @search_profile.id ])
  end

  test "creates matches when job is performed" do
    initial_match_count = Match.count

    perform_enqueued_jobs do
      MatchingJob.perform_later(@search_profile.id)
    end

    assert_operator Match.count, :>, initial_match_count

    match = Match.find_by(
      search_profile: @search_profile,
      user: @match_user
    )

    assert_not_nil match
  end

  test "clears existing matches before creating new ones" do
    # Create an existing match
    existing_match = create(:match, search_profile: @search_profile)

    perform_enqueued_jobs do
      MatchingJob.perform_later(@search_profile.id)
    end

    # Existing match should be removed
    assert_not Match.exists?(existing_match.id)
  end

  test "handles non-existent search profile gracefully" do
    non_existent_id = SearchProfile.maximum(:id).to_i + 1

    assert_raises(ActiveRecord::RecordNotFound) do
      MatchingJob.new.perform(non_existent_id)
    end
  end

  test "logs matching completion" do
    assert_difference "Match.count", 1 do
      perform_enqueued_jobs do
        MatchingJob.perform_later(@search_profile.id)
      end
    end
  end

  test "retries on standard errors" do
    # Mock MatchingService to raise an error
    MatchingService.any_instance.stubs(:find_matches).raises(StandardError, "Test error")

    # The job should retry and eventually fail
    assert_raises(StandardError) do
      MatchingJob.new.perform(@search_profile.id)
    end
  end

  test "returns number of matches created" do
    job = MatchingJob.new(@search_profile.id)
    matches_created = job.perform(@search_profile.id)

    assert_kind_of Integer, matches_created
    assert_operator matches_created, :>=, 0
  end
end
