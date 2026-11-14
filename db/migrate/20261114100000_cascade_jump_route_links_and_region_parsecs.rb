# frozen_string_literal: true

# DeleteSectorJob hard-deletes a sector and relies on the database cascading
# through parsecs and star systems. These foreign keys were created without
# ON DELETE CASCADE, so deleting a sector raised ActiveRecord::InvalidForeignKey.
class CascadeJumpRouteLinksAndRegionParsecs < ActiveRecord::Migration[8.1]
  def up
    replace_fk :jump_route_links, :star_systems, :from_star_system_id
    replace_fk :jump_route_links, :star_systems, :to_star_system_id
    replace_fk :region_parsecs, :parsecs, :parsec_id
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def replace_fk(table, to_table, column)
    remove_foreign_key table, to_table, column: column, if_exists: true
    add_foreign_key table, to_table, column: column, on_delete: :cascade
  end
end
