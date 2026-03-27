class AddHexCoordinatesToParsecs < ActiveRecord::Migration[8.1]
  def up
    add_column :parsecs, :q, :integer
    add_column :parsecs, :r, :integer
    add_column :parsecs, :s, :integer

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
      CREATE TRIGGER trigger_parsecs_set_hex_coordinates
      BEFORE INSERT OR UPDATE OF x, y
      ON parsecs
      FOR EACH ROW
      EXECUTE FUNCTION parsecs_set_hex_coordinates();
    SQL

    execute <<~SQL
      UPDATE parsecs
      SET
        q = x,
        r = y - ((x - (x & 1)) / 2),
        s = -(x + (y - ((x - (x & 1)) / 2)));
    SQL

    change_column_null :parsecs, :q, false
    change_column_null :parsecs, :r, false
    change_column_null :parsecs, :s, false

    add_index :parsecs, [:q, :r, :s]
  end

  def down
    remove_index :parsecs, [:q, :r, :s]

    execute 'DROP TRIGGER IF EXISTS trigger_parsecs_set_hex_coordinates ON parsecs;'
    execute 'DROP FUNCTION IF EXISTS parsecs_set_hex_coordinates();'

    remove_column :parsecs, :s
    remove_column :parsecs, :r
    remove_column :parsecs, :q
  end
end