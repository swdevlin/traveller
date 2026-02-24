class ChangeStellarObjectsToOrbitStar < ActiveRecord::Migration[8.1]
  def change
    # Add companion FK (self-referential, for companion stars)
    add_reference :stellar_objects, :companion, null: true,
                  foreign_key: { to_table: :stellar_objects, on_delete: :nullify },
                  index: true
  end
end
