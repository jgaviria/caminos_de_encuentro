FactoryBot.define do
  factory :address do
    association :user
    country { "Colombia" }
    state { "Antioquia" }
    city { "Medellin" }
    neighborhood { "El Poblado" }
    street_address { "Carrera 43A #5-15" }
    postal_code { "050021" }

    trait :bogota do
      state { "Cundinamarca" }
      city { "Bogota" }
      neighborhood { "Zona Rosa" }
      street_address { "Calle 82 #11-15" }
      postal_code { "110221" }
    end

    trait :cali do
      state { "Valle del Cauca" }
      city { "Cali" }
      neighborhood { "San Fernando" }
      street_address { "Avenida 6 #20-30" }
      postal_code { "760032" }
    end

    factory :search_profile_address do
      association :search_profile
      user { nil }
    end
  end
end
