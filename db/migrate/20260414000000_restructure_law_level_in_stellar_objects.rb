# frozen_string_literal: true

class RestructureLawLevelInStellarObjects < ActiveRecord::Migration[8.1]
  TYPES = %w[TerrestrialPlanet Moon Planetoid PlanetoidBelt].freeze

  def up
    execute <<~SQL
      UPDATE stellar_objects
      SET data = (data - 'law_level_code')
                 || jsonb_build_object('law_level', jsonb_build_object('code', (data->>'law_level_code')::integer))
      WHERE data ? 'law_level_code'
        AND type IN (#{TYPES.map { |t| "'#{t}'" }.join(', ')})
    SQL
  end

  def down
    execute <<~SQL
      UPDATE stellar_objects
      SET data = (data - 'law_level')
                 || jsonb_build_object('law_level_code', (data->'law_level'->>'code')::integer)
      WHERE data ? 'law_level'
        AND type IN (#{TYPES.map { |t| "'#{t}'" }.join(', ')})
    SQL
  end
end
