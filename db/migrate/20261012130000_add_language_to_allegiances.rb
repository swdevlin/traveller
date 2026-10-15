class AddLanguageToAllegiances < ActiveRecord::Migration[8.1]
  def change
    add_column :allegiances, :language, :string
  end
end
