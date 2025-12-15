class AddAbbreviationToSubsector < ActiveRecord::Migration[8.1]
  def change
    add_column :subsectors, :abbreviation, :string
  end
end
