class CreateAddresses < ActiveRecord::Migration[7.0]
  def change
    create_table :addresses do |t|
      t.references :user, null: true, foreign_key: true # For the seeker's address
      t.references :search_profile, null: true, foreign_key: true # For the person being searched for
      t.string :country, null: false, default: "Colombia"
      t.string :state
      t.string :city
      t.string :neighborhood
      t.string :street_address
      t.string :postal_code

      t.timestamps
    end
  end
end
