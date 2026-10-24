class CastStellarObjectRatingFieldsToIntegers < ActiveRecord::Migration[8.1]
  FIELDS = %w[
    habitability_rating biomass_rating biocomplexity_rating
    biodiversity_rating compatibility_rating resource_rating
    berthing_cost refined_fuel_cost unrefined_fuel_cost
  ].freeze

  def up
    FIELDS.each do |field|
      execute <<~SQL.squish
        UPDATE stellar_objects
        SET data = jsonb_set(data, '{#{field}}', to_jsonb((trim(data ->> '#{field}'))::integer))
        WHERE jsonb_typeof(data -> '#{field}') = 'string' AND trim(data ->> '#{field}') ~ '^-?[0-9]+$'
      SQL
    end
  end

  def down
  end
end
