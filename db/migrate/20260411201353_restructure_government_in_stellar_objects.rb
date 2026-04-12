# frozen_string_literal: true

class RestructureGovernmentInStellarObjects < ActiveRecord::Migration[8.1]
  TYPES = %w[TerrestrialPlanet Moon Planetoid PlanetoidBelt].freeze

  def up
    execute <<~SQL
      UPDATE stellar_objects
      SET data = (data - 'government_code')
                 || jsonb_build_object('government', jsonb_build_object('code', (data->>'government_code')::integer))
      WHERE data ? 'government_code'
        AND type IN (#{TYPES.map { |t| "'#{t}'" }.join(', ')})
    SQL
  end

  def down
    execute <<~SQL
      UPDATE stellar_objects
      SET data = (data - 'government')
                 || jsonb_build_object('government_code', (data->'government'->>'code')::integer)
      WHERE data ? 'government'
        AND type IN (#{TYPES.map { |t| "'#{t}'" }.join(', ')})
    SQL
  end
end
