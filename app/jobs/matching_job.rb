class MatchingJob < ApplicationJob
  queue_as :default
  
  retry_on StandardError, wait: 5.seconds, attempts: 3

  def perform(search_profile_id)
    search_profile = SearchProfile.find(search_profile_id)
    Rails.logger.info "Starting background matching for search profile #{search_profile_id}"
    
    # Clear existing matches for this profile to avoid duplicates
    search_profile.matches.destroy_all
    
    matching_service = MatchingService.new(search_profile)
    matches_created = matching_service.find_matches
    
    Rails.logger.info "Background matching completed for search profile #{search_profile_id}: #{matches_created} matches created"
    
    # Optionally send notification to user about completed matching
    # UserMailer.matching_completed(search_profile.user, matches_created).deliver_now
    
    matches_created
  rescue ActiveRecord::RecordNotFound => e
    Rails.logger.error "Search profile #{search_profile_id} not found: #{e.message}"
    raise
  rescue StandardError => e
    Rails.logger.error "Error in matching job for search profile #{search_profile_id}: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    raise
  end
end