class CreateBuildings < ActiveRecord::Migration[8.1]
  def change
    create_table :buildings do |t|
      t.string :address
      t.string :city
      t.string :owner

      t.timestamps
    end
  end
end
