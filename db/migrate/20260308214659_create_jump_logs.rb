class CreateJumpLogs < ActiveRecord::Migration[8.1]
  def change
    create_table :jump_logs do |t|
      t.references :ship, null: false, foreign_key: true
      t.references :from_parsec, null: false, foreign_key: { to_table: :parsecs }
      t.references :to_parsec, null: false, foreign_key: {to_table: :parsecs}
      t.integer :depart_year
      t.integer :depart_day
      t.integer :arrive_year
      t.integer :arrive_day
      t.integer :sequence
      t.text :notes

      t.timestamps
    end
  end
end
