class AddTagsToMapObjects < ActiveRecord::Migration[8.0]
  def change
    %i[sectors subsectors star_systems stellar_objects].each do |table|
      add_column table, :tags, :string, array: true, default: [], null: false
    end
  end
end
