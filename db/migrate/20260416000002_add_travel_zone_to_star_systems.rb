class AddTravelZoneToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_reference :star_systems, :travel_zone, foreign_key: true, null: true
  end
end
