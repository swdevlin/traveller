class CreateStellarObjectTradeCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :stellar_object_trade_codes do |t|
      t.references :stellar_object, null: false, foreign_key: true
      t.references :trade_code, null: false, foreign_key: true

      t.timestamps
    end
    add_index :stellar_object_trade_codes, %i[stellar_object_id trade_code_id], unique: true
  end
end
