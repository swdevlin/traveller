class AddRankModifierToRulebooks < ActiveRecord::Migration[8.1]
  def change
    add_column :rulebooks, :rank_modifier, :decimal, precision: 4, scale: 2, default: 0.0, null: false
  end
end
