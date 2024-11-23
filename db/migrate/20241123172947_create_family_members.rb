class CreateFamilyMembers < ActiveRecord::Migration[7.2]
  def change
    create_table :family_members do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :relationship
      t.string :first_name
      t.string :last_name

      t.timestamps
    end
  end
end
