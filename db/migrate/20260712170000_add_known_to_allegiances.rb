class AddKnownToAllegiances < ActiveRecord::Migration[8.1]
  def change
    add_column :allegiances, :known, :boolean, default: true, null: false
  end
end
