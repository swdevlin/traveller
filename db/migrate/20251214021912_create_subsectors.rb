class CreateSubsectors < ActiveRecord::Migration[8.1]
  def change
    create_table :subsectors do |t|
      t.string :name
      t.integer :x, null: false
      t.integer :y, null: false
      t.references :sector, null: false, foreign_key: { on_delete: :cascade }

      t.timestamps
    end
  end
end
