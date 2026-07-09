class AddLockedToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :locked, :boolean, default: false
  end
end
