class CreateRegionComponents < ActiveRecord::Migration[8.1]
  def change
    create_table :region_components do |t|
      t.references :region, null: false, foreign_key: true
      t.references :source_sector, null: false, foreign_key: { to_table: :sectors }
      t.integer :position, null: false, default: 0
      t.string :input_type
      t.string :external_component_key
      t.jsonb :data

      t.timestamps
    end

    add_index :region_components,
              %i[region_id source_sector_id external_component_key],
              unique: true,
              name: 'index_region_components_on_region_sector_and_external_key'
  end
end
