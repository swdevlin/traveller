class AddWorldCountsToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :terrestrial_count, :integer, null: false, default: 0
    add_column :star_systems, :belt_count, :integer, null: false, default: 0
    add_column :star_systems, :gas_giant_count, :integer, null: false, default: 0
  end
end
