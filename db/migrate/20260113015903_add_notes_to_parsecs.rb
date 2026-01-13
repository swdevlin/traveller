class AddNotesToParsecs < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :note, :text
  end
end
