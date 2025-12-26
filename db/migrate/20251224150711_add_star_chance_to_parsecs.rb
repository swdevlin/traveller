class AddStarChanceToParsecs < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :star_chance, :float, default: 50
    add_column :subsectors, :star_chance, :float, default: 50
    add_column :sectors, :star_chance, :float, default: 50
  end
end
