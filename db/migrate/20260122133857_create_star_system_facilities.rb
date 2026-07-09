class CreateStarSystemFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :star_system_facilities do |t|
      t.references :star_system, null: false, foreign_key: { on_delete: :cascade }
      t.references :facility, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
    add_index :star_system_facilities, %i[star_system_id facility_id], unique: true
  end
end
