class StellarObjectSti < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :type, :string
  end
end
