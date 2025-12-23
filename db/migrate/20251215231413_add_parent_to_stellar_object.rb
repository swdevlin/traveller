class AddParentToStellarObject < ActiveRecord::Migration[8.1]
  def change
    add_reference :stellar_objects, :orbiting, foreign_key: { to_table: :stellar_objects }, null: true
  end
end
