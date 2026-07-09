class RestructureRegionParsecs < ActiveRecord::Migration[8.1]
  def up
    # Clear all existing region data
    execute 'TRUNCATE region_parsecs, region_components, regions RESTART IDENTITY CASCADE'

    # Step 1: Replace region_parsecs columns
    remove_index :region_parsecs, name: 'idx_on_region_component_id_parsec_id_kind_eed2e06fae'
    remove_index :region_parsecs, name: 'index_region_parsecs_on_region_component_id'
    remove_column :region_parsecs, :region_component_id

    add_column :region_parsecs, :region_id, :bigint, null: false
    add_column :region_parsecs, :position, :integer

    add_index :region_parsecs, %i[region_id parsec_id kind], unique: true, name: 'idx_region_parsecs_on_region_parsec_kind'
    add_index :region_parsecs, :region_id, name: 'index_region_parsecs_on_region_id'

    # Step 2: Drop region_components table
    drop_table :region_components

    # Step 3: Add player_visible to regions
    add_column :regions, :player_visible, :boolean, null: false, default: false
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
