class AddRouteTypeAndFilterColumnsToJumpRoutes < ActiveRecord::Migration[8.1]
  def change
    add_column :jump_routes, :route_type,               :string, null: false, default: 'network'
    add_column :jump_routes, :refueling,                :string
    add_column :jump_routes, :excluded_travel_zone_ids, :integer, array: true, default: []
    add_reference :jump_routes, :from_star_system, foreign_key: { to_table: :star_systems }, null: true
    add_reference :jump_routes, :to_star_system,   foreign_key: { to_table: :star_systems }, null: true
  end
end
