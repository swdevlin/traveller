class AddAuToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :au, :float
  end
end
