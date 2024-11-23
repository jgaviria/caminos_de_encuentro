class CreateProfiles < ActiveRecord::Migration[7.2]
  def change
    create_table :profiles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :last_name
      t.date :dob
      t.string :city_of_birth
      t.string :country_of_birth
      t.string :mother_name
      t.string :father_name
      t.string :last_known_city
      t.string :last_known_neighborhood
      t.integer :status

      t.timestamps
    end
  end
end
