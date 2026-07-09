class AddLabelColourToParsecs < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :label_colour, :string
  end
end
