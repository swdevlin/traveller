class FixParsecHexCoordinates < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      CREATE OR REPLACE FUNCTION parsecs_set_hex_coordinates()
      RETURNS trigger AS $$
      BEGIN
        NEW.q := NEW.x;
        NEW.r := -NEW.y - ((NEW.x - (NEW.x & 1)) / 2);
        NEW.s := -NEW.q - NEW.r;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      UPDATE parsecs
      SET q = x,
          r = -y - ((x - (x & 1)) / 2),
          s = -(x + (-y - ((x - (x & 1)) / 2)));
    SQL
  end

  def down
    execute <<~SQL
      CREATE OR REPLACE FUNCTION parsecs_set_hex_coordinates()
      RETURNS trigger AS $$
      BEGIN
        NEW.q := NEW.x;
        NEW.r := NEW.y - ((NEW.x - (NEW.x & 1)) / 2);
        NEW.s := -NEW.q - NEW.r;
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;
    SQL

    execute <<~SQL
      UPDATE parsecs
      SET q = x,
          r = y - ((x - (x & 1)) / 2),
          s = -(x + (y - ((x - (x & 1)) / 2)));
    SQL
  end
end
