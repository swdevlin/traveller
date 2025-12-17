class AddNotesAndBuildToSubsector < ActiveRecord::Migration[8.1]
  def change
    add_column :subsectors, :notes, :text
    add_column :subsectors, :build, :text
  end
end
