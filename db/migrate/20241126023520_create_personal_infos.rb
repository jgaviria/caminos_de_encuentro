class CreatePersonalInfos < ActiveRecord::Migration[7.0]
  def change
    create_table :personal_infos do |t|
      t.references :user, null: false, foreign_key: true
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.string :phone_number

      t.timestamps
    end
  end
end
