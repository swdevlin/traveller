class AddAllegianceToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_reference :star_systems,
                  :allegiance,
                  null: true,
                  foreign_key: { to_table: :allegiances, on_delete: :nullify },
                  index: true
  end
end
