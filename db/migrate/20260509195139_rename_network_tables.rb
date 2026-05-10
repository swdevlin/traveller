class RenameNetworkTables < ActiveRecord::Migration[8.1]
  def up
    drop_table :network_links
    drop_table :communication_networks

    create_table :networks do |t|
      t.string :name
      t.string :colour
      t.integer :max_jump
      t.boolean :known
      t.text :notes
      t.timestamps
    end

    create_table :network_links do |t|
      t.references :network, null: false, foreign_key: true
      t.bigint :from_star_system_id, null: false
      t.bigint :to_star_system_id, null: false
      t.timestamps
    end

    add_foreign_key :network_links, :star_systems, column: :from_star_system_id
    add_foreign_key :network_links, :star_systems, column: :to_star_system_id
    add_index :network_links, :to_star_system_id
    add_index :network_links, %i[from_star_system_id to_star_system_id], unique: true
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
