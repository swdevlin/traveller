# frozen_string_literal: true

class CreateNetworkLinks < ActiveRecord::Migration[8.1]
  def change
    create_table :network_links do |t|
      t.references :communication_network, null: false, foreign_key: true
      t.bigint :from_star_system_id, null: false
      t.bigint :to_star_system_id, null: false

      t.timestamps
    end

    add_index :network_links, %i[from_star_system_id to_star_system_id], unique: true, name: 'index_network_links_unique_pair'
    add_index :network_links, :to_star_system_id

    add_foreign_key :network_links, :star_systems, column: :from_star_system_id
    add_foreign_key :network_links, :star_systems, column: :to_star_system_id
  end
end
