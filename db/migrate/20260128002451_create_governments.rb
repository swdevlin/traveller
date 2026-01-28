class CreateGovernments < ActiveRecord::Migration[8.1]
  def change
    create_table :governments do |t|
      t.integer :code
      t.string :government_type
      t.text :description

      t.timestamps
    end
    add_index :governments, :code, unique: true
  end
end
