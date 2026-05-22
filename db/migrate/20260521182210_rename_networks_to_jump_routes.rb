# frozen_string_literal: true

class RenameNetworksToJumpRoutes < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :network_links, :networks

    rename_table :networks,      :jump_routes
    rename_table :network_links, :jump_route_links

    rename_column :jump_route_links, :network_id, :jump_route_id

    add_foreign_key :jump_route_links, :jump_routes, column: :jump_route_id

    execute 'ALTER INDEX IF EXISTS index_network_links_on_network_id RENAME TO index_jump_route_links_on_jump_route_id'
    execute 'ALTER INDEX IF EXISTS index_network_links_on_to_star_system_id RENAME TO index_jump_route_links_on_to_star_system_id'
    execute 'ALTER INDEX IF EXISTS idx_on_from_star_system_id_to_star_system_id_5dc5d7aaf1 RENAME TO index_jump_route_links_on_from_to_star_system_ids'

    add_column :jump_routes, :line_style, :string,  null: false, default: 'solid'
    add_column :jump_routes, :line_width, :integer, null: false, default: 4
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
