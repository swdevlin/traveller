# frozen_string_literal: true

# The generator has sent negative tech level capabilities (e.g. -1 space transport), but a
# tech level can never be below zero. Clamp any stored in stellar_objects.data to 0, touching
# the owning star systems so cached API responses are refreshed.
class ClampNegativeTechLevelCapabilities < ActiveRecord::Migration[8.1]
  def up
    # Star system payloads are cached against the system's updated_at, so touch the affected systems.
    execute <<~SQL.squish
      UPDATE star_systems SET updated_at = NOW()
      WHERE id IN (
        SELECT star_system_id FROM stellar_objects
        WHERE jsonb_typeof(data -> 'tech_level') = 'object'
          AND EXISTS (
            SELECT 1 FROM jsonb_each(data -> 'tech_level')
            WHERE jsonb_typeof(value) = 'number' AND (value #>> '{}')::numeric < 0
          )
      )
    SQL

    execute <<~SQL.squish
      UPDATE stellar_objects
      SET data = jsonb_set(data, '{tech_level}', (
        SELECT jsonb_object_agg(
          key,
          CASE WHEN jsonb_typeof(value) = 'number' AND (value #>> '{}')::numeric < 0 THEN to_jsonb(0) ELSE value END
        )
        FROM jsonb_each(data -> 'tech_level')
      ))
      WHERE jsonb_typeof(data -> 'tech_level') = 'object'
        AND EXISTS (
          SELECT 1 FROM jsonb_each(data -> 'tech_level')
          WHERE jsonb_typeof(value) = 'number' AND (value #>> '{}')::numeric < 0
        )
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
