class MatchingService
  include ActionView::Helpers::TextHelper

  MINIMUM_MATCH_SCORE = 0.3

  # Weights for different matching criteria
  WEIGHTS = {
    exact_name: 0.45,  # Increased for better exact match scoring
    fuzzy_name: 0.25,
    location: 0.25,    # Adjusted to balance total
    phone: 0.03,
    temporal: 0.02
  }.freeze

  def initialize(search_profile)
    @search_profile = search_profile
    @search_address = @search_profile.address
  end

  def find_matches
    Rails.logger.info "Starting matching process for search profile #{@search_profile.id}"

    potential_matches = find_potential_matches
    scored_matches = calculate_match_scores(potential_matches)

    # Only create matches above minimum threshold
    qualified_matches = scored_matches.select { |match| match[:score] >= MINIMUM_MATCH_SCORE }

    create_match_records(qualified_matches)

    Rails.logger.info "Created #{qualified_matches.size} matches for search profile #{@search_profile.id}"
    qualified_matches.size
  end

  private

  def find_potential_matches
    # Use efficient queries with proper indexes
    candidates = []

    # 1. Exact name matches (fastest)
    exact_matches = PersonalInfo.joins(:user)
                                .where("LOWER(first_name) = ? AND LOWER(last_name) = ?",
                                       @search_profile.first_name.downcase,
                                       @search_profile.last_name.downcase)
                                .includes(:user, user: :address)

    candidates.concat(exact_matches.map { |pi| { personal_info: pi, match_type: :exact } })

    # 2. Fuzzy name matches using trigram similarity (if extension available)
    if candidates.empty?
      begin
        fuzzy_matches = PersonalInfo.joins(:user)
                                    .where("similarity(first_name, ?) > 0.6 OR similarity(last_name, ?) > 0.6",
                                           @search_profile.first_name, @search_profile.last_name)
                                    .includes(:user, user: :address)

        candidates.concat(fuzzy_matches.map { |pi| { personal_info: pi, match_type: :fuzzy } })
      rescue ActiveRecord::StatementInvalid
        # pg_trgm extension not available, skip fuzzy matching
        Rails.logger.warn "pg_trgm extension not available, skipping fuzzy matching"
      end
    end

    # 3. Partial name matches (first name only, last name only)
    if candidates.size < 10
      partial_matches = PersonalInfo.joins(:user)
                                    .where("LOWER(first_name) = ? OR LOWER(last_name) = ?",
                                           @search_profile.first_name.downcase,
                                           @search_profile.last_name.downcase)
                                    .includes(:user, user: :address)
                                    .limit(50)

      candidates.concat(partial_matches.map { |pi| { personal_info: pi, match_type: :partial } })
    end

    # Remove duplicates and exclude same user
    candidates.uniq { |c| c[:personal_info].user_id }
              .reject { |c| c[:personal_info].user_id == @search_profile.user_id }
  end

  def calculate_match_scores(candidates)
    candidates.map do |candidate|
      personal_info = candidate[:personal_info]
      user_address = personal_info.user.address

      score = 0.0
      score_details = {}

      # Name similarity scoring
      name_score = calculate_name_similarity(personal_info, candidate[:match_type])
      score += name_score * WEIGHTS[:exact_name] if candidate[:match_type] == :exact
      score += name_score * WEIGHTS[:fuzzy_name] if candidate[:match_type] != :exact
      score_details[:name] = name_score

      # Location similarity scoring
      if @search_address && user_address
        location_score = calculate_location_similarity(user_address)
        score += location_score * WEIGHTS[:location]
        score_details[:location] = location_score
      end

      # Phone number similarity (if available)
      if personal_info.phone_number.present?
        phone_score = calculate_phone_similarity(personal_info)
        score += phone_score * WEIGHTS[:phone]
        score_details[:phone] = phone_score
      end

      # Temporal relevance (creation date proximity)
      temporal_score = calculate_temporal_relevance(personal_info)
      score += temporal_score * WEIGHTS[:temporal]
      score_details[:temporal] = temporal_score

      {
        personal_info: personal_info,
        user: personal_info.user,
        score: [ score, 1.0 ].min, # Cap at 1.0
        score_details: score_details
      }
    end.sort_by { |match| -match[:score] }
  end

  def calculate_name_similarity(personal_info, match_type)
    return 1.0 if match_type == :exact

    first_similarity = string_similarity(@search_profile.first_name, personal_info.first_name)
    last_similarity = string_similarity(@search_profile.last_name, personal_info.last_name)

    # Give higher weight to last name matches
    (first_similarity * 0.4 + last_similarity * 0.6)
  end

  def calculate_location_similarity(user_address)
    return 0.0 unless @search_address

    score = 0.0

    # Country match (highest weight) - use fuzzy matching
    country_similarity = location_fuzzy_similarity(@search_address.country, user_address.country)
    score += 0.4 * country_similarity

    # State match - use fuzzy matching
    state_similarity = location_fuzzy_similarity(@search_address.state, user_address.state)
    score += 0.3 * state_similarity

    # City match - use fuzzy matching (this handles Medellin vs Medellín)
    city_similarity = location_fuzzy_similarity(@search_address.city, user_address.city)
    score += 0.2 * city_similarity

    # Neighborhood match - use fuzzy matching
    neighborhood_similarity = location_fuzzy_similarity(@search_address.neighborhood, user_address.neighborhood)
    score += 0.1 * neighborhood_similarity

    score
  end

  def calculate_phone_similarity(personal_info)
    # Implement phone number similarity logic
    # This could include partial matches, similar patterns, etc.
    0.0 # Placeholder
  end

  def calculate_temporal_relevance(personal_info)
    # More recent profiles might be more relevant
    days_ago = (Time.current - personal_info.created_at) / 1.day
    return 1.0 if days_ago <= 30
    return 0.5 if days_ago <= 365
    return 0.1 if days_ago <= 1825 # 5 years
    0.0
  end

  def string_similarity(str1, str2)
    return 0.0 if str1.blank? || str2.blank?
    return 1.0 if str1.downcase == str2.downcase

    # Use Levenshtein distance for similarity
    distance = levenshtein_distance(str1.downcase, str2.downcase)
    max_length = [ str1.length, str2.length ].max
    return 0.0 if max_length == 0

    1.0 - (distance.to_f / max_length)
  end

  def levenshtein_distance(str1, str2)
    matrix = Array.new(str1.length + 1) { Array.new(str2.length + 1) }

    (0..str1.length).each { |i| matrix[i][0] = i }
    (0..str2.length).each { |j| matrix[0][j] = j }

    (1..str1.length).each do |i|
      (1..str2.length).each do |j|
        cost = str1[i - 1] == str2[j - 1] ? 0 : 1
        matrix[i][j] = [
          matrix[i - 1][j] + 1,     # deletion
          matrix[i][j - 1] + 1,     # insertion
          matrix[i - 1][j - 1] + cost  # substitution
        ].min
      end
    end

    matrix[str1.length][str2.length]
  end

  def location_fuzzy_similarity(loc1, loc2)
    return 0.0 if loc1.blank? || loc2.blank?

    # Normalize locations: remove accents, downcase, strip whitespace
    normalized_loc1 = normalize_location_string(loc1)
    normalized_loc2 = normalize_location_string(loc2)

    # First check exact match after normalization
    return 1.0 if normalized_loc1 == normalized_loc2

    # Use string similarity with normalized strings
    similarity = string_similarity(normalized_loc1, normalized_loc2)

    # Give high scores for very close matches (like Medellin vs Medellín)
    # If similarity is > 0.8, consider it a very good match
    similarity >= 0.8 ? [ similarity, 0.95 ].min : similarity
  end

  def normalize_location_string(location)
    return "" if location.blank?

    # Remove accents and normalize common variations
    normalized = location.downcase.strip

    # Remove common accents in Spanish location names
    normalized = normalized.tr("áéíóúüñ", "aeiouun")

    # Handle common variations
    location_variations = {
      "bogota" => "bogota",
      "medellin" => "medellin",
      "cali" => "cali",
      "barranquilla" => "barranquilla",
      "cartagena" => "cartagena"
    }

    # Check if it's a known variation
    location_variations[normalized] || normalized
  end

  def same_location?(loc1, loc2)
    # Keep this method for backward compatibility, but use fuzzy similarity
    location_fuzzy_similarity(loc1, loc2) >= 0.95
  end

  def create_match_records(qualified_matches)
    matches_to_create = qualified_matches.map do |match_data|
      {
        search_profile_id: @search_profile.id,
        user_id: match_data[:user].id,
        similarity_score: match_data[:score].round(3),
        is_verified: false,
        created_at: Time.current,
        updated_at: Time.current
      }
    end

    # Bulk insert for better performance
    Match.insert_all(matches_to_create) if matches_to_create.any?
  end
end
