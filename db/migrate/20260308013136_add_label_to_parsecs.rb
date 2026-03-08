class AddLabelToParsecs < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :label, :string
    add_column :parsecs, :player_visible, :boolean, default: false
  end
end
