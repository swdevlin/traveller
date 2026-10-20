class CastStellarObjectSophontIdsToIntegers < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE stellar_objects
      SET data = jsonb_set(data, '{sophont_id}', to_jsonb((data ->> 'sophont_id')::integer))
      WHERE jsonb_typeof(data -> 'sophont_id') = 'string' AND data ->> 'sophont_id' ~ '^[0-9]+$'
    SQL
  end

  def down
  end
end
