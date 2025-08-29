class AddIndexesForMatchingOptimization < ActiveRecord::Migration[7.2]
  def change
    # Add composite indexes for efficient name matching
    add_index :personal_infos, "LOWER(first_name), LOWER(last_name)", name: "index_personal_infos_on_lower_names"
    add_index :search_profiles, "LOWER(first_name), LOWER(last_name)", name: "index_search_profiles_on_lower_names"

    # Add indexes for similarity scoring and geographic matching
    add_index :addresses, [ :country, :state, :city ], name: "index_addresses_on_location"
    add_index :addresses, :country
    add_index :addresses, :state
    add_index :addresses, :city

    # Add indexes for match processing
    add_index :matches, [ :similarity_score, :is_verified ], name: "index_matches_on_score_and_verification"
    add_index :matches, :created_at
    add_index :matches, [ :search_profile_id, :similarity_score ], name: "index_matches_on_profile_and_score"

    # Add partial indexes for active matches
    add_index :matches, :search_profile_id, where: "is_verified = false", name: "index_unverified_matches"

    # Add trigram indexes for fuzzy name matching (requires pg_trgm extension)
    enable_extension "pg_trgm" unless extension_enabled?("pg_trgm")

    add_index :personal_infos, :first_name, using: :gin, opclass: :gin_trgm_ops
    add_index :personal_infos, :last_name, using: :gin, opclass: :gin_trgm_ops
    add_index :search_profiles, :first_name, using: :gin, opclass: :gin_trgm_ops
    add_index :search_profiles, :last_name, using: :gin, opclass: :gin_trgm_ops
  end
end
