class ChangeDefaultOfPageNumberOffsetOnRulebooks < ActiveRecord::Migration[8.1]
  def change
    change_column_default :rulebooks, :page_number_offset, from: 0, to: 1
  end
end
