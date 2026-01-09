class CreateTradeCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :trade_codes do |t|
      t.string :code, null: false, limit: 2
      t.string :definition, null: false

      t.timestamps
    end

    add_index :trade_codes, :code, unique: true
  end
end
