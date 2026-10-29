class AddTagsToRegions < ActiveRecord::Migration[8.0]
  def change
    add_column :regions, :tags, :string, array: true, default: [], null: false
  end
end
