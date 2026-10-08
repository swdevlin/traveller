class CreatePlanetMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :planet_maps do |t|
      t.references :stellar_object, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.string :inputs_digest, null: false

      t.timestamps
    end
  end
end
