class CreateCities < ActiveRecord::Migration[8.1]
  def change
    create_table :cities do |t|
      t.references :stellar_object, null: false, foreign_key: { on_delete: :cascade }
      t.string :name
      t.bigint :population, null: false

      t.timestamps
    end

    add_index :cities, %i[stellar_object_id population]
  end
end
