class CreateAddresses < ActiveRecord::Migration[7.2]
  def change
    create_table :addresses do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :address_line
      t.string :city
      t.string :country
      t.date :date_from
      t.date :date_to

      t.timestamps
    end
  end
end
