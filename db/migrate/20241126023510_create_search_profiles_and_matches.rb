class CreateSearchProfilesAndMatches < ActiveRecord::Migration[7.0]
  def change
    create_table :search_profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :middle_name
      t.string :last_name

      t.timestamps
    end

    create_table :matches do |t|
      t.references :search_profile, null: false, foreign_key: true
      t.references :user, null: true, foreign_key: true # For the seeker's address
      t.float :similarity_score, default: 0.0
      t.boolean :is_verified, default: false

      t.timestamps
    end
  end
end
