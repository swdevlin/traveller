class CreateParsecs < ActiveRecord::Migration[8.1]
  def change
    create_table :parsecs do |t|
      t.integer :x, null: false
      t.integer :y, null: false
      t.references :sector, null: false, foreign_key: true

      t.timestamps
    end
  end
end
