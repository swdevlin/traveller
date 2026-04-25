class CreateSocialCharacteristicsPresets < ActiveRecord::Migration[8.1]
  def change
    create_table :social_characteristics_presets do |t|
      t.string :name, null: false
      t.jsonb  :settings, null: false, default: {}
      t.timestamps
    end
    add_index :social_characteristics_presets, :name, unique: true
  end
end
