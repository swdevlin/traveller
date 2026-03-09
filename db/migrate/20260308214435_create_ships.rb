class CreateShips < ActiveRecord::Migration[8.1]
  def change
    create_table :ships do |t|
      t.string :name
      t.integer :jump_drive

      t.timestamps
    end
  end
end
