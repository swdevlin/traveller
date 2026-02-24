class ChangeSizeCodeToString < ActiveRecord::Migration[8.1]
  def change
    remove_column :stellar_objects, :size_code, :integer
    add_column :stellar_objects, :size_code, :string
  end
end
