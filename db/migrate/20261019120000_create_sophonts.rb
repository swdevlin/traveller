class CreateSophonts < ActiveRecord::Migration[8.1]
  def change
    create_table :sophonts do |t|
      t.string :name, null: false
      t.string :language
      t.references :home_system, foreign_key: { to_table: :star_systems, on_delete: :nullify }
      t.text :referee_notes
      t.text :player_notes

      t.timestamps
    end

    add_index :sophonts, 'lower(name)', unique: true, name: 'index_sophonts_on_lower_name'
  end
end
