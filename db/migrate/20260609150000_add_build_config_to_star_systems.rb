class AddBuildConfigToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :build_config, :text
  end
end
