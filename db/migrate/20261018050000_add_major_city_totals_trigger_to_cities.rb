class AddMajorCityTotalsTriggerToCities < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION recalculate_major_city_totals(stellar_object_ids bigint[])
      RETURNS void AS $$
      BEGIN
        UPDATE stellar_objects
        SET data = jsonb_set(
          COALESCE(stellar_objects.data, '{}'::jsonb),
          '{population}',
          COALESCE(stellar_objects.data -> 'population', '{}'::jsonb) || jsonb_build_object(
            'majorCities', totals.city_count,
            'majorCityPopulation', totals.city_population
          )
        )
        FROM (
          SELECT stellar_objects.id,
                 (SELECT COUNT(*) FROM cities WHERE cities.stellar_object_id = stellar_objects.id) AS city_count,
                 (SELECT SUM(cities.population) FROM cities WHERE cities.stellar_object_id = stellar_objects.id) AS city_population
          FROM stellar_objects
          WHERE stellar_objects.id = ANY(stellar_object_ids)
        ) totals
        WHERE stellar_objects.id = totals.id;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE OR REPLACE FUNCTION cities_after_insert_major_city_totals() RETURNS trigger AS $$
      BEGIN
        PERFORM recalculate_major_city_totals(ARRAY(SELECT DISTINCT stellar_object_id FROM new_rows));
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION cities_after_update_major_city_totals() RETURNS trigger AS $$
      BEGIN
        PERFORM recalculate_major_city_totals(ARRAY(
          SELECT stellar_object_id FROM new_rows UNION SELECT stellar_object_id FROM old_rows
        ));
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;

      CREATE OR REPLACE FUNCTION cities_after_delete_major_city_totals() RETURNS trigger AS $$
      BEGIN
        PERFORM recalculate_major_city_totals(ARRAY(SELECT DISTINCT stellar_object_id FROM old_rows));
        RETURN NULL;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      CREATE TRIGGER trigger_cities_insert_major_city_totals
        AFTER INSERT ON cities
        REFERENCING NEW TABLE AS new_rows
        FOR EACH STATEMENT EXECUTE FUNCTION cities_after_insert_major_city_totals();

      CREATE TRIGGER trigger_cities_update_major_city_totals
        AFTER UPDATE ON cities
        REFERENCING OLD TABLE AS old_rows NEW TABLE AS new_rows
        FOR EACH STATEMENT EXECUTE FUNCTION cities_after_update_major_city_totals();

      CREATE TRIGGER trigger_cities_delete_major_city_totals
        AFTER DELETE ON cities
        REFERENCING OLD TABLE AS old_rows
        FOR EACH STATEMENT EXECUTE FUNCTION cities_after_delete_major_city_totals();
    SQL

    execute 'SELECT recalculate_major_city_totals(ARRAY(SELECT DISTINCT stellar_object_id FROM cities))'
  end

  def down
    execute <<~SQL
      DROP TRIGGER IF EXISTS trigger_cities_insert_major_city_totals ON cities;
      DROP TRIGGER IF EXISTS trigger_cities_update_major_city_totals ON cities;
      DROP TRIGGER IF EXISTS trigger_cities_delete_major_city_totals ON cities;
      DROP FUNCTION IF EXISTS cities_after_insert_major_city_totals();
      DROP FUNCTION IF EXISTS cities_after_update_major_city_totals();
      DROP FUNCTION IF EXISTS cities_after_delete_major_city_totals();
      DROP FUNCTION IF EXISTS recalculate_major_city_totals(bigint[]);
    SQL
  end
end
