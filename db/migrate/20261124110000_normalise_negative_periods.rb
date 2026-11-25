# frozen_string_literal: true

# The generator gives a retrograde orbit as a negative period, which the app showed as a negative number of days
# while the retrograde flag stayed false. Store the period as a positive number of days and set the flag instead.
class NormaliseNegativePeriods < ActiveRecord::Migration[8.1]
  # CASE, because SQL may evaluate the cast before an AND'd type check and fail on a period that isn't a number.
  NEGATIVE = "CASE WHEN jsonb_typeof(data -> 'period') = 'number' THEN (data ->> 'period')::numeric < 0 ELSE false END"

  def up
    # Star system payloads are cached against the system's updated_at, so touch the affected systems.
    execute <<~SQL.squish
      UPDATE star_systems SET updated_at = NOW()
      WHERE id IN (SELECT star_system_id FROM stellar_objects WHERE #{NEGATIVE})
    SQL

    execute <<~SQL.squish
      UPDATE stellar_objects
      SET data = data || jsonb_build_object('period', abs((data ->> 'period')::numeric), 'retrograde', true)
      WHERE #{NEGATIVE}
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
