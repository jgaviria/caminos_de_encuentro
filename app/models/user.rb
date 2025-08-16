class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
         
  has_one :personal_info, dependent: :destroy
  has_one :address, dependent: :destroy
  has_many :search_profiles, dependent: :destroy
  has_many :matches
  
  # Admin functionality
  def admin?
    admin == true
  end
end
