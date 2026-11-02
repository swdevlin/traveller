class AddSourceToPlanetMaps < ActiveRecord::Migration[8.1]
  def change
    add_column :planet_maps, :source, :string, null: false, default: 'generated'
  end
end
