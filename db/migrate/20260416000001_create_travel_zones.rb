class CreateTravelZones < ActiveRecord::Migration[8.1]
  def change
    create_table :travel_zones do |t|
      t.string :code,      null: false
      t.string :name,      null: false
      t.string :colour,    null: false
      t.boolean :protected, null: false, default: false

      t.timestamps
    end

    add_index :travel_zones, :code, unique: true
  end
end
