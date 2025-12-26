class CreateStellarObjects < ActiveRecord::Migration[8.1]
  def change
    create_table :stellar_objects do |t|
      t.string :name
      t.integer :orbit_x
      t.integer :orbit_y
      t.references :parsec, null: true, foreign_key: true
      t.references :star_system, null: true, foreign_key: true
      t.float :inclination
      t.float :eccentricity
      t.float :orbit
      t.float :effective_hzco_deviation
      t.float :mass
      t.float :diameter
      t.json :characteristics
      t.text :notes

      t.timestamps
    end

    add_check_constraint :stellar_objects,
      "(parsec_id IS NOT NULL) OR (star_system_id IS NOT NULL)",
      name: "stellar_objects_parsec_or_star_system_present"
  end
end
