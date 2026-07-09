class AddTidalLockTargetToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_reference :stellar_objects, :tidal_lock_target, null: true,
                  foreign_key: { to_table: :stellar_objects, on_delete: :nullify }
  end
end
