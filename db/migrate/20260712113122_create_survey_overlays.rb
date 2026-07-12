class CreateSurveyOverlays < ActiveRecord::Migration[8.1]
  def change
    create_table :survey_overlays do |t|
      t.string  :name,      null: false
      t.boolean :known,     null: false, default: false
      t.string  :colour,    null: false
      t.boolean :enabled,   null: false, default: true
      t.jsonb   :rule_data, null: false, default: {}
      t.integer :position,  null: false

      t.timestamps
    end
  end
end
