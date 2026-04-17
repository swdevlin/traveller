class CreateCommunicationNetworks < ActiveRecord::Migration[8.1]
  def change
    create_table :communication_networks do |t|
      t.string :name
      t.string :colour
      t.integer :max_jump
      t.boolean :known
      t.text :notes

      t.timestamps
    end
  end
end
