# frozen_string_literal: true

class CreateStarSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :star_systems do |t|
      t.string :name
      t.references :parsec, null: false, foreign_key: { on_delete: :cascade }

      t.references :main_world,
                   null: true,
                   foreign_key: { to_table: :stellar_objects, on_delete: :nullify }

      t.json :meta
      t.timestamps
    end

    add_foreign_key :stellar_objects, :star_systems, column: :star_system_id, on_delete: :cascade
  end
end
