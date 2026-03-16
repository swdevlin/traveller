# frozen_string_literal: true

class EnablePgTrgmAndSearchIndexes < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'pg_trgm'
    execute 'CREATE INDEX index_star_systems_on_name_trgm ON star_systems USING gin (name shared_extensions.gin_trgm_ops)'
    execute 'CREATE INDEX index_sectors_on_name_trgm ON sectors USING gin (name shared_extensions.gin_trgm_ops)'
    execute 'CREATE INDEX index_subsectors_on_name_trgm ON subsectors USING gin (name shared_extensions.gin_trgm_ops)'
  end

  def down
    remove_index :star_systems, name: 'index_star_systems_on_name_trgm'
    remove_index :sectors,      name: 'index_sectors_on_name_trgm'
    remove_index :subsectors,   name: 'index_subsectors_on_name_trgm'
    disable_extension 'pg_trgm'
  end
end
