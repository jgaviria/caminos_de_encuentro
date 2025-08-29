FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    password_confirmation { "password123" }

    trait :admin do
      # Add admin attribute when available
      # admin { true }
    end

    factory :user_with_personal_info do
      after(:create) do |user|
        create(:personal_info, user: user)
      end
    end

    factory :user_with_address do
      after(:create) do |user|
        create(:address, user: user)
      end
    end

    factory :complete_user do
      after(:create) do |user|
        create(:personal_info, user: user)
        create(:address, user: user)
      end
    end
  end
end
