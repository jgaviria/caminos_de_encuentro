class CreateEducations < ActiveRecord::Migration[7.2]
  def change
    create_table :educations do |t|
      t.references :profile, null: false, foreign_key: true
      t.string :school_name
      t.integer :level
      t.date :date_from
      t.date :date_to

      t.timestamps
    end
  end
end
