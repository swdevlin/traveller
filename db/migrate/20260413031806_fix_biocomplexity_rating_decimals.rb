# frozen_string_literal: true

class FixBiocomplexityRatingDecimals < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE stellar_objects
      SET data = jsonb_set(
        data,
        '{biocomplexity_rating}',
        to_jsonb((data->>'biocomplexity_rating')::numeric::integer)
      )
      WHERE data ? 'biocomplexity_rating'
        AND (data->>'biocomplexity_rating') ~ '^-?[0-9]+\.[0-9]+$'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
