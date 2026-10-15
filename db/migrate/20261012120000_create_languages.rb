class CreateLanguages < ActiveRecord::Migration[8.1]
  def change
    create_table :languages do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.text :corpus, null: false, default: ''

      t.timestamps
    end

    add_index :languages, :key, unique: true
  end
end
