class SearchProfile < ApplicationRecord
  include ActionView::Helpers::DateHelper
  
  belongs_to :user
  has_one :address, dependent: :destroy
  has_many :matches, dependent: :destroy

  validates :first_name, :last_name, presence: true

  # Match status enum
  enum :match_status, {
    pending: 0,      # Created but not yet matched
    processing: 1,   # Currently being processed
    completed: 2,    # Matching completed
    failed: 3        # Matching failed with error
  }

  # Scopes for filtering by match status
  scope :with_matches, -> { where('match_count > 0') }
  scope :without_matches, -> { where(match_count: 0) }
  scope :recently_matched, -> { where('last_matched_at > ?', 1.day.ago) }

  # Helper methods
  def has_been_matched?
    last_matched_at.present?
  end

  def match_status_display
    case match_status
    when 'pending'
      I18n.t('user.pending_match')
    when 'processing'
      I18n.t('user.processing_match')
    when 'completed'
      if has_matches?
        if match_count == 1
          "#{match_count} #{I18n.t('user.match_found')}"
        else
          "#{match_count} #{I18n.t('user.matches_found')}"
        end
      else
        I18n.t('user.no_matches_found_status')
      end
    when 'failed'
      I18n.t('user.match_failed')
    end
  end

  def has_matches?
    match_count > 0
  end

  def last_matched_display
    return I18n.t('user.never_matched') unless last_matched_at
    
    if last_matched_at > 1.day.ago
      "#{time_ago_in_words(last_matched_at)} #{I18n.t('general.ago')}"
    else
      I18n.l(last_matched_at, format: :long)
    end
  end

  def match_status_color
    case match_status
    when 'pending'
      'yellow'
    when 'processing'
      'blue'
    when 'completed'
      has_matches? ? 'green' : 'gray'
    when 'failed'
      'red'
    end
  end

end
