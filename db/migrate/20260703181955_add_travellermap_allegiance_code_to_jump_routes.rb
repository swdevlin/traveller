class AddTravellermapAllegianceCodeToJumpRoutes < ActiveRecord::Migration[8.1]
  def change
    add_column :jump_routes, :travellermap_allegiance_code, :string
    add_index :jump_routes, :travellermap_allegiance_code, unique: true
  end
end
