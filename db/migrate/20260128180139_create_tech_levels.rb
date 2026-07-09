class CreateTechLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :tech_levels do |t|
      t.integer :code
      t.string :energy
      t.string :electronics
      t.string :manufacturing
      t.string :medical
      t.string :environmental
      t.string :land
      t.string :sea
      t.string :air
      t.string :space
      t.string :personal_military
      t.string :heavy_military
      t.string :notes

      t.timestamps
    end
    add_index :tech_levels, :code, unique: true
  end
end
