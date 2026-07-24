class CreateMeasurements < ActiveRecord::Migration[8.1]
  def change
    create_table :measurements do |t|
      t.references :location, null: false, foreign_key: true
      t.datetime :starts_at
      t.datetime :ends_at
      t.decimal :value_kwh, precision: 15, scale: 6

      t.timestamps
    end
    add_index :measurements, [ :location_id, :starts_at ], unique: true
    add_index :measurements, :starts_at, using: :brin
  end
end
