class AddUniqueIndexToSubsectorsOnSectorAndXAndY < ActiveRecord::Migration[8.1]
  def change
        add_index :subsectors, [:sector_id, :x, :y], unique: true
  end
end
