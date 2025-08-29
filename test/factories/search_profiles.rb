FactoryBot.define do
  factory :search_profile do
    association :user
    first_name { "John" }
    middle_name { "Robert" }
    last_name { "Doe" }

    trait :maria do
      first_name { "Maria" }
      middle_name { "Isabel" }
      last_name { "Garcia" }
    end

    trait :carlos do
      first_name { "Carlos" }
      middle_name { "Andres" }
      last_name { "Rodriguez" }
    end

    trait :with_address do
      after(:create) do |search_profile|
        create(:search_profile_address, search_profile: search_profile)
      end
    end

    factory :complete_search_profile do
      after(:create) do |search_profile|
        create(:search_profile_address, search_profile: search_profile)
      end
    end
  end
end
