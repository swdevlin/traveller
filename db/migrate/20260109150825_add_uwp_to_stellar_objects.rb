class AddUwpToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :uwp, :string
  end
end
