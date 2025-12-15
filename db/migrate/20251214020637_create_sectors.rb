class CreateSectors < ActiveRecord::Migration[8.1]
  def change
    create_table :sectors do |t|
      t.string :name
      t.integer :x
      t.integer :y
      t.string :abbreviation

      t.timestamps
    end
  end
end
