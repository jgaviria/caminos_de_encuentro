class Match < ApplicationRecord
  belongs_to :search_profile
  belongs_to :matched_user, class_name: 'User', foreign_key: 'matched_user_id'

  validates :similarity_score, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
end
