class AddMatchTrackingToSearchProfiles < ActiveRecord::Migration[7.2]
  def change
    add_column :search_profiles, :match_status, :integer, default: 0, null: false
    add_column :search_profiles, :match_count, :integer, default: 0, null: false
    add_column :search_profiles, :last_matched_at, :datetime

    add_index :search_profiles, :match_status
    add_index :search_profiles, :last_matched_at
  end
end
