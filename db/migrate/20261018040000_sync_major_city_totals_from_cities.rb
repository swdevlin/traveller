class SyncMajorCityTotalsFromCities < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL.squish
      UPDATE stellar_objects
      SET data = jsonb_set(
        jsonb_set(data, '{population,majorCities}', to_jsonb(totals.city_count)),
        '{population,majorCityPopulation}', to_jsonb(totals.city_population)
      )
      FROM (
        SELECT stellar_object_id, COUNT(*) AS city_count, SUM(population) AS city_population
        FROM cities
        GROUP BY stellar_object_id
      ) totals
      WHERE stellar_objects.id = totals.stellar_object_id
        AND jsonb_typeof(stellar_objects.data -> 'population') = 'object'
    SQL
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
