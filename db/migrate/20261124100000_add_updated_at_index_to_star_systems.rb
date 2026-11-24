# frozen_string_literal: true

# The starmap checks MAX(star_systems.updated_at) on every load to decide whether the
# all-sectors map is stale. An index turns that from a sequential scan into a single probe.
class AddUpdatedAtIndexToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_index :star_systems, :updated_at
  end
end
