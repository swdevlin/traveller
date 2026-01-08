class AddNotesToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :notes, :text
  end
end
