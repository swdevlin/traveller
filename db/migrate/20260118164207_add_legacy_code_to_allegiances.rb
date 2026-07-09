class AddLegacyCodeToAllegiances < ActiveRecord::Migration[8.1]
  def change
    add_column :allegiances, :legacy_code, :string
  end
end
