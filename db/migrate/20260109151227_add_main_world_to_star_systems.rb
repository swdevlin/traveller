class AddMainWorldToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_reference :star_systems, :main_world, foreign_key: { to_table: 'stellar_objects' }, index: true
  end
end
