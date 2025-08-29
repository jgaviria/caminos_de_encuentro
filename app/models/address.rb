class Address < ApplicationRecord
  belongs_to :user, optional: true
  belongs_to :search_profile, optional: true

  validates :country, presence: true
end
