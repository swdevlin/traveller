class AddIconToFacilities < ActiveRecord::Migration[8.1]
  def change
    add_column :facilities, :icon_class, :string, null: true
  end
end
