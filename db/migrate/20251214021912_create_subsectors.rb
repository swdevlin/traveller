class CreateSubsectors < ActiveRecord::Migration[8.1]
  def change
    create_table :subsectors do |t|
      t.string :name
      t.integer :x, null: false
      t.integer :y, null: false
      t.references :sector, foreign_key: true, null: false

      t.timestamps
    end
  end
end
