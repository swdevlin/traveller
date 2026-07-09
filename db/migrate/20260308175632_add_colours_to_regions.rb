class AddColoursToRegions < ActiveRecord::Migration[8.1]
  def change
    add_column :regions, :border_colour, :string
    add_column :regions, :colour, :string
    add_column :regions, :label_colour, :string
    add_column :regions, :label_x, :integer
    add_column :regions, :label_y, :integer
  end
end
