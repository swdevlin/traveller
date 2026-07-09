class AddColoursToAllegiances < ActiveRecord::Migration[8.1]
  def change
    add_column :allegiances, :background_colour, :string
    add_column :allegiances, :border_colour, :string
  end
end
