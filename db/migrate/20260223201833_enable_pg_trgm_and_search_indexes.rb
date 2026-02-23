# frozen_string_literal: true

class EnablePgTrgmAndSearchIndexes < ActiveRecord::Migration[8.1]
  def up
    enable_extension 'pg_trgm'
    add_index :star_systems, :name, using: :gin, opclass: :gin_trgm_ops, name: 'index_star_systems_on_name_trgm'
    add_index :sectors,      :name, using: :gin, opclass: :gin_trgm_ops, name: 'index_sectors_on_name_trgm'
    add_index :subsectors,   :name, using: :gin, opclass: :gin_trgm_ops, name: 'index_subsectors_on_name_trgm'
  end

  def down
    remove_index :star_systems, name: 'index_star_systems_on_name_trgm'
    remove_index :sectors,      name: 'index_sectors_on_name_trgm'
    remove_index :subsectors,   name: 'index_subsectors_on_name_trgm'
    disable_extension 'pg_trgm'
  end
end
