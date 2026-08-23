class DropStarSystemTradeCodes < ActiveRecord::Migration[8.1]
  def change
    drop_table :star_system_trade_codes do |t|
      t.references :star_system, null: false, foreign_key: { on_delete: :cascade }
      t.references :trade_code, null: false, foreign_key: { on_delete: :cascade }
      t.timestamps
    end
  end
end
