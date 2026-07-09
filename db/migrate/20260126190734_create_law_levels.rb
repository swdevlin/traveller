class CreateLawLevels < ActiveRecord::Migration[8.1]
  def change
    create_table :law_levels do |t|
      t.integer :code
      t.string :armour
      t.string :weapons
      t.string :economic_law
      t.string :criminal_law
      t.string :private_law
      t.string :personal_law
      t.text :notes

      t.timestamps
    end

    add_index :law_levels, :code, unique: true
  end
end
