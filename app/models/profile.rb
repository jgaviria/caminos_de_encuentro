class Profile < ApplicationRecord
  belongs_to :user
  has_many :addresses, dependent: :destroy
  # Validations can be added here, e.g.,
  validates :first_name, :last_name, presence: true
end