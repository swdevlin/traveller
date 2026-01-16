class ChangeStellarObjectsToOrbitStar < ActiveRecord::Migration[8.1]
  def change
    remove_column :stellar_objects, :orbiting_id, :integer

    add_reference :stellar_objects,
                  :orbiting_star,
                  null: true,
                  foreign_key: { to_table: :stars, on_delete: :cascade },
                  index: true
  end
end
