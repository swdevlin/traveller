# frozen_string_literal: true

class FixFacilityRelayStationCode < ActiveRecord::Migration[8.1]
  def up
    # Rename R (Relay Station) → RS if RS doesn't already exist, preserving
    # StarSystemFacility links. Tenants seeded with RS already skip this step.
    execute <<~SQL
      UPDATE facilities SET code = 'RS'
      WHERE code = 'R' AND name = 'Relay Station'
        AND NOT EXISTS (SELECT 1 FROM facilities WHERE code = 'RS')
    SQL
    # Ensure R = Research Station in all schema contexts.
    execute <<~SQL
      INSERT INTO facilities (code, name, traveller_map_code, created_at, updated_at)
      VALUES ('R', 'Research Station', '', NOW(), NOW())
      ON CONFLICT (code) DO UPDATE SET name = 'Research Station'
    SQL
  end

  def down
    execute "DELETE FROM facilities WHERE code = 'R' AND name = 'Research Station'"
    execute <<~SQL
      UPDATE facilities SET code = 'R'
      WHERE code = 'RS'
        AND NOT EXISTS (SELECT 1 FROM facilities WHERE code = 'R')
    SQL
  end
end
