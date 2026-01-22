class CreateFacilities < ActiveRecord::Migration[8.1]
  def change
    create_table :facilities do |t|
      t.string :code, null: false
      t.string :name
      t.string :traveller_map_code

      t.timestamps
    end
    add_index :facilities, :code, unique: true unless index_exists?(:facilities, :code, unique: true)
  end
end
