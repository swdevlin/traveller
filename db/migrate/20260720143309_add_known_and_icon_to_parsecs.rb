class AddKnownAndIconToParsecs < ActiveRecord::Migration[8.1]
  def change
    rename_column :parsecs, :player_visible, :known
    change_column :parsecs, :label, :text
    add_column :parsecs, :visible, :boolean, default: true, null: false
    add_column :parsecs, :icon_class, :string
  end
end
