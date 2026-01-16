class CreateStars < ActiveRecord::Migration[8.1]
  def change
    create_table :stars do |t|
      t.string :name
      t.float :orbit
      t.float :orbit_x
      t.float :orbit_y
      t.float :inclination
      t.float :eccentricity
      t.string :stellar_class
      t.string :stellar_type
      t.integer :stellar_subtype
      t.boolean :is_protostar
      t.float :mass
      t.float :diameter
      t.float :temperature
      t.float :age
      t.string :colour
      t.float :period
      t.float :baseline
      t.float :spread
      t.string :orbit_sequence
      t.float :minimum_orbit
      t.float :luminosity
      t.float :hzco
      t.float :jump_shadow
      t.float :au
      t.integer :survey_index
      t.integer :scan_points
      t.references :star_system, null: true, foreign_key: { on_delete: :cascade }
      t.references :parsec, null: true, foreign_key: { on_delete: :cascade }
      t.references :companion, null: true, foreign_key: { to_table: :stars, on_delete: :nullify }
      t.references :orbiting, null: true, foreign_key: { to_table: :stars, on_delete: :cascade }

      t.timestamps
    end
  end
end
