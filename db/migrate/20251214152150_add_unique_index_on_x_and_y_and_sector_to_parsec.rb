class AddUniqueIndexOnXAndYAndSectorToParsec < ActiveRecord::Migration[8.1]
  def change
    add_index :parsecs, [:sector_id, :x, :y], unique: true
  end
end
