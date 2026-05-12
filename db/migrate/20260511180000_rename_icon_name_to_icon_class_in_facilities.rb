class RenameIconNameToIconClassInFacilities < ActiveRecord::Migration[8.1]
  def up
    if column_exists?(:facilities, :icon_name)
      rename_column :facilities, :icon_name, :icon_class
    end
  end

  def down
    if column_exists?(:facilities, :icon_class)
      rename_column :facilities, :icon_class, :icon_name
    end
  end
end
