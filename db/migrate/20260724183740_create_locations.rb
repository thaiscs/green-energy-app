class CreateLocations < ActiveRecord::Migration[8.1]
  def change
    create_table :locations do |t|
      t.references :unit, null: false, foreign_key: true
      t.string :type
      t.string :external_id

      t.timestamps
    end
    add_index :locations, :external_id, unique: true
    add_index :locations, :type
    add_index :locations, [ :unit_id, :type ], unique: true
  end
end
