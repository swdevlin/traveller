class AddNotesAndBuildToSectors < ActiveRecord::Migration[8.1]
  def change
    add_column :sectors, :notes, :text
    add_column :sectors, :build, :text
  end
end
