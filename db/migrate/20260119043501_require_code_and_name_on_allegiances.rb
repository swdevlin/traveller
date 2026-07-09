class RequireCodeAndNameOnAllegiances < ActiveRecord::Migration[8.1]
  def change
    change_column_null :allegiances, :code, false
    change_column_null :allegiances, :name, false

    add_index :allegiances, :code, unique: true unless index_exists?(:allegiances, :code, unique: true)
  end
end
