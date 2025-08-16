class Match < ApplicationRecord
  belongs_to :search_profile
  belongs_to :user, optional: true
end
