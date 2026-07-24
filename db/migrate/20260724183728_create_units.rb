class CreateUnits < ActiveRecord::Migration[8.1]
  def change
    create_table :units do |t|
      t.references :building, null: false, foreign_key: true
      t.string :label
      t.string :resident_name

      t.timestamps
    end
  end
end
