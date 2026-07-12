class RemoveKnownFromSurveyOverlays < ActiveRecord::Migration[8.1]
  def change
    remove_column :survey_overlays, :known, :boolean, null: false, default: false
  end
end
