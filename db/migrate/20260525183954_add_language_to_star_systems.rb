class AddLanguageToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :language, :string
  end
end
