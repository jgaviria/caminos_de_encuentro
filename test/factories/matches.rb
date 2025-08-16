FactoryBot.define do
  factory :match do
    association :search_profile
    association :user
    similarity_score { 0.8 }
    is_verified { false }
    
    trait :verified do
      is_verified { true }
    end
    
    trait :high_confidence do
      similarity_score { 0.95 }
    end
    
    trait :medium_confidence do
      similarity_score { 0.7 }
    end
    
    trait :low_confidence do
      similarity_score { 0.4 }
    end
    
    trait :exact_match do
      similarity_score { 1.0 }
    end
  end
end