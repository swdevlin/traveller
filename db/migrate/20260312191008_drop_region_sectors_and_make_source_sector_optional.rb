class DropRegionSectorsAndMakeSourceSectorOptional < ActiveRecord::Migration[8.1]
  def change
    drop_table :region_sectors do |t|
      t.bigint :region_id, null: false
      t.bigint :sector_id, null: false
      t.timestamps
    end

    change_column_null :region_components, :source_sector_id, true
  end
end
