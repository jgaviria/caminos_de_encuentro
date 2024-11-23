json.extract! profile, :id, :user_id, :first_name, :last_name, :dob, :city_of_birth, :country_of_birth, :mother_name, :father_name, :last_known_city, :last_known_neighborhood, :status, :created_at, :updated_at
json.url profile_url(profile, format: :json)
