class AddSizeCodeToStellarObjects < ActiveRecord::Migration[8.1]
  def change
    add_column :stellar_objects, :size_code, :integer
  end
end
