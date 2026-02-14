class AddSurveyIndexToStarSystems < ActiveRecord::Migration[8.1]
  def change
    add_column :star_systems, :survey_index, :integer, default: 0
  end
end
