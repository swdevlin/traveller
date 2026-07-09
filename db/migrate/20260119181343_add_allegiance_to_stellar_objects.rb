class AddAllegianceToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_reference :stellar_objects,
                  :allegiance,
                  null: true,
                  foreign_key: { to_table: :allegiances, on_delete: :nullify },
                  index: true
  end
end
