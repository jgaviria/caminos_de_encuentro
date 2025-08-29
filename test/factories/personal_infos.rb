FactoryBot.define do
  factory :personal_info do
    association :user
    first_name { "John" }
    middle_name { "Robert" }
    last_name { "Doe" }
    phone_number { "+57 300 123 4567" }

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

    trait :with_similar_name do
      first_name { "Jon" } # Similar to John
      last_name { "Doe" }
    end

    trait :partial_match do
      first_name { "John" }
      last_name { "Smith" } # Different last name
    end
  end
end
