class NormalizeStarNumericData < ActiveRecord::Migration[8.1]
  # Star edits previously saved these jsonb fields as strings (e.g. "4").
  INTEGER_FIELDS = %w[stellar_subtype temperature].freeze
  FLOAT_FIELDS = %w[luminosity hzco minimum_allowable_orbit age].freeze

  NUMERIC_PATTERN = '^\s*-?[0-9]+(\.[0-9]+)?\s*$'

  def up
    INTEGER_FIELDS.each { |field| normalize(field, 'round((%s)::numeric)::integer') }
    FLOAT_FIELDS.each { |field| normalize(field, '(%s)::numeric') }
  end

  def down
    # no-op — the string values were never valid
  end

  private

  def normalize(field, cast)
    value = "data->>'#{field}'"
    execute <<~SQL
      UPDATE stellar_objects
      SET data = jsonb_set(
        data,
        '{#{field}}',
        CASE
          WHEN #{value} ~ '#{NUMERIC_PATTERN}' THEN to_jsonb(#{format(cast, value)})
          ELSE 'null'::jsonb
        END
      )
      WHERE type = 'Star'
        AND jsonb_typeof(data->'#{field}') = 'string'
    SQL
  end
end
