class SearchProfile < ApplicationRecord
  belongs_to :user
  has_one :address, dependent: :destroy
  has_many :matches, dependent: :destroy

  validates :first_name, :last_name, presence: true
end
