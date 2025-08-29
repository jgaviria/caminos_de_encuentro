# Seeds file for Caminos de Encuentro
# This creates consistent test data including admin users, regular users,
# search profiles, and matches for testing the application.

puts "🌱 Seeding Caminos de Encuentro database..."

# Clear existing data in development environment
if Rails.env.development?
  puts "🧹 Cleaning existing data..."
  Match.destroy_all
  SearchProfile.destroy_all
  PersonalInfo.destroy_all
  Address.destroy_all
  User.destroy_all
end

# Create Admin Users
puts "👑 Creating admin users..."

admin1 = User.find_or_create_by!(email: "admin@caminosdeencuentro.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.admin = true
end

admin2 = User.find_or_create_by!(email: "admin@test.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
  user.admin = true
end

puts "✅ Created #{User.where(admin: true).count} admin users"

# Create Regular Users (Seekers)
puts "👥 Creating seeker users..."

seeker_users = [
  {
    email: "maria.garcia@example.com",
    personal_info: {
      first_name: "Maria",
      last_name: "Garcia",
      phone_number: "+57 300 123 4567"
    },
    address: {
      country: "Colombia",
      state: "Antioquia",
      city: "Medellín",
      neighborhood: "El Poblado"
    }
  },
  {
    email: "carlos.rodriguez@example.com",
    personal_info: {
      first_name: "Carlos",
      last_name: "Rodriguez",
      phone_number: "+57 301 987 6543"
    },
    address: {
      country: "Colombia",
      state: "Cundinamarca",
      city: "Bogotá",
      neighborhood: "Chapinero"
    }
  },
  {
    email: "ana.martinez@example.com",
    personal_info: {
      first_name: "Ana",
      last_name: "Martinez",
      phone_number: "+57 302 555 1234"
    },
    address: {
      country: "Colombia",
      state: "Valle del Cauca",
      city: "Cali",
      neighborhood: "San Fernando"
    }
  }
]

seekers = []
seeker_users.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.admin = false
  end

  # Create personal info
  personal_info = user.personal_info || user.build_personal_info
  personal_info.update!(user_data[:personal_info])

  # Create address
  address = user.address || user.build_address
  address.update!(user_data[:address])

  seekers << user
end

puts "✅ Created #{seekers.count} seeker users"

# Create Target Users (People being searched for)
puts "🎯 Creating target users..."

target_users = [
  {
    email: "juan.garcia@example.com",
    personal_info: {
      first_name: "Juan",
      last_name: "Garcia",
      phone_number: "+57 300 111 2222"
    },
    address: {
      country: "Colombia",
      state: "Antioquia",
      city: "Medellín",
      neighborhood: "Laureles"
    }
  },
  {
    email: "luis.rodriguez@example.com",
    personal_info: {
      first_name: "Luis",
      last_name: "Rodriguez",
      phone_number: "+57 301 333 4444"
    },
    address: {
      country: "Colombia",
      state: "Cundinamarca",
      city: "Bogotá",
      neighborhood: "Zona Rosa"
    }
  },
  {
    email: "sofia.martinez@example.com",
    personal_info: {
      first_name: "Sofia",
      last_name: "Martinez",
      phone_number: "+57 302 777 8888"
    },
    address: {
      country: "Colombia",
      state: "Valle del Cauca",
      city: "Cali",
      neighborhood: "Granada"
    }
  }
]

targets = []
target_users.each do |user_data|
  user = User.find_or_create_by!(email: user_data[:email]) do |u|
    u.password = "password123"
    u.password_confirmation = "password123"
    u.admin = false
  end

  # Create personal info
  personal_info = user.personal_info || user.build_personal_info
  personal_info.update!(user_data[:personal_info])

  # Create address
  address = user.address || user.build_address
  address.update!(user_data[:address])

  targets << user
end

puts "✅ Created #{targets.count} target users"

# Create Search Profiles
puts "🔍 Creating search profiles..."

search_profiles_data = [
  {
    user: seekers[0], # Maria Garcia
    first_name: "Juan",
    last_name: "Garcia",
    middle_name: "Carlos"
  },
  {
    user: seekers[1], # Carlos Rodriguez
    first_name: "Luis",
    last_name: "Rodriguez",
    middle_name: nil
  },
  {
    user: seekers[2], # Ana Martinez
    first_name: "Sofia",
    last_name: "Martinez",
    middle_name: "Elena"
  },
  {
    user: seekers[0], # Maria Garcia (second profile)
    first_name: "Pedro",
    last_name: "Garcia",
    middle_name: nil
  }
]

search_profiles = []
search_profiles_data.each do |profile_data|
  profile = SearchProfile.find_or_create_by!(
    user: profile_data[:user],
    first_name: profile_data[:first_name],
    last_name: profile_data[:last_name]
  ) do |sp|
    sp.middle_name = profile_data[:middle_name]
  end
  search_profiles << profile
end

puts "✅ Created #{search_profiles.count} search profiles"

# Create Matches using the MatchingService
puts "💘 Creating matches..."

require_relative '../app/services/matching_service'

matches_created = 0
search_profiles.each do |profile|
  begin
    # Use the MatchingService to create realistic matches
    matching_service = MatchingService.new(profile)
    potential_matches = matching_service.find_matches

    potential_matches.each do |match_data|
      match = Match.find_or_create_by!(
        search_profile: profile,
        user: match_data[:user]
      ) do |m|
        m.similarity_score = match_data[:score]
        m.is_verified = [ true, false ].sample # Random verification status
      end
      matches_created += 1
    end
  rescue => e
    puts "⚠️  Warning: Could not create matches for #{profile.first_name} #{profile.last_name}: #{e.message}"
  end
end

# Create some manual high-quality matches if the service didn't create enough
if matches_created == 0
  puts "📝 Creating manual matches..."

  # Maria Garcia searching for Juan Garcia -> Juan Garcia (high similarity)
  Match.find_or_create_by!(
    search_profile: search_profiles[0],
    user: targets[0]
  ) do |match|
    match.similarity_score = 0.95
    match.is_verified = false
  end

  # Carlos Rodriguez searching for Luis Rodriguez -> Luis Rodriguez (high similarity)
  Match.find_or_create_by!(
    search_profile: search_profiles[1],
    user: targets[1]
  ) do |match|
    match.similarity_score = 0.88
    match.is_verified = true
  end

  # Ana Martinez searching for Sofia Martinez -> Sofia Martinez (high similarity)
  Match.find_or_create_by!(
    search_profile: search_profiles[2],
    user: targets[2]
  ) do |match|
    match.similarity_score = 0.92
    match.is_verified = false
  end

  matches_created = 3
end

puts "✅ Created #{matches_created} matches"

# Summary
puts "\n🎉 Database seeding completed!"
puts "=" * 50
puts "📊 Summary:"
puts "   👑 Admin users: #{User.where(admin: true).count}"
puts "   👥 Regular users: #{User.where(admin: false).count}"
puts "   🔍 Search profiles: #{SearchProfile.count}"
puts "   💘 Matches: #{Match.count}"
puts "   ✅ Verified matches: #{Match.where(is_verified: true).count}"
puts "   ⏳ Pending matches: #{Match.where(is_verified: false).count}"
puts "\n🔑 Admin Login Credentials:"
puts "   Email: admin@caminosdeencuentro.com"
puts "   Email: admin@test.com"
puts "   Password: password123"
puts "\n🧪 Test User Credentials:"
puts "   Any user email listed above"
puts "   Password: password123"
puts "\n🚀 You can now start your server and test the application!"
puts "   Run: bundle exec rails server"
puts "   Visit: http://localhost:3000"
