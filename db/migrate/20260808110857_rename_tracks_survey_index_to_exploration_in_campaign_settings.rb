class RenameTracksSurveyIndexToExplorationInCampaignSettings < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE campaigns
      SET settings = (settings - 'tracks_survey_index') || jsonb_build_object('exploration', settings->'tracks_survey_index')
      WHERE settings ? 'tracks_survey_index'
    SQL
  end

  def down
    execute <<~SQL
      UPDATE campaigns
      SET settings = (settings - 'exploration') || jsonb_build_object('tracks_survey_index', settings->'exploration')
      WHERE settings ? 'exploration'
    SQL
  end
end
