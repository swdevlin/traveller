class CreateStarSystemTradeCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :star_system_trade_codes do |t|
      t.references :star_system, null: false, foreign_key: true
      t.references :trade_code, null: false, foreign_key: true

      t.timestamps
    end
    add_index :star_system_trade_codes, %i[star_system_id trade_code_id], unique: true
  end
end
