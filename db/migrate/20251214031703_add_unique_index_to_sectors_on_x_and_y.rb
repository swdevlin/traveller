class AddUniqueIndexToSectorsOnXAndY < ActiveRecord::Migration[8.1]
  def change
    add_index :sectors, [:x, :y], unique: true
  end
end
