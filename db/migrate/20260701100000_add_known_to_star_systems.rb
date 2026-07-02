class AddKnownToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :known, :boolean, default: false, null: false
  end
end
