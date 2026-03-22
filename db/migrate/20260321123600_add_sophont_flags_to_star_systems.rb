class AddSophontFlagsToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :native_sophont, :boolean, default: false, null: false
    add_column :star_systems, :extinct_sophont, :boolean, default: false, null: false
  end
end
