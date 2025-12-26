class CreateStarSystems < ActiveRecord::Migration[8.1]
  def change
    create_table :star_systems do |t|
      t.string :name
      t.references :parsec, null: false, foreign_key: true
      t.json :meta

      t.timestamps
    end
  end
end
