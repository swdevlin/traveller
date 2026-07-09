class CreateRegionSectors < ActiveRecord::Migration[8.1]
  def change
    create_table :region_sectors do |t|
      t.references :region, null: false, foreign_key: true
      t.references :sector, null: false, foreign_key: true

      t.timestamps
    end

    add_index :region_sectors, %i[region_id sector_id], unique: true
  end
end
