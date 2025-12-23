class AddSurveyIndexToParsecs < ActiveRecord::Migration[8.1]
  def change
    add_column :parsecs, :survey_index, :integer, default: 0
  end
end
