class BatchMatchingJob < ApplicationJob
  queue_as :default

  def perform(batch_size: 10)
    Rails.logger.info "Starting batch matching process with batch size #{batch_size}"

    # Find search profiles that need matching (new profiles or profiles without recent matches)
    profiles_to_match = SearchProfile.left_joins(:matches)
                                     .where(matches: { id: nil })
                                     .or(SearchProfile.left_joins(:matches)
                                                      .where("matches.created_at < ?", 1.week.ago))
                                     .distinct
                                     .limit(batch_size)

    Rails.logger.info "Found #{profiles_to_match.count} profiles to match"

    profiles_to_match.find_each do |search_profile|
      MatchingJob.perform_later(search_profile.id)
    end

    Rails.logger.info "Enqueued #{profiles_to_match.count} matching jobs"
  end
end
