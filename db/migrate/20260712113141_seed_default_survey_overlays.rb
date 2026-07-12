class SeedDefaultSurveyOverlays < ActiveRecord::Migration[8.1]
  DEFAULTS = [
    { name: 'Native Sophonts', colour: '#22c55e', enabled: true,
      rule_data: { groups: [[{ field: 'native_sophont', operator: 'eq', negate: false, values: ['true'] }]] } },
    { name: 'Extinct Sophonts', colour: '#6b7280', enabled: true,
      rule_data: { groups: [[{ field: 'extinct_sophont', operator: 'eq', negate: false, values: ['true'] }]] } }
  ].freeze

  def up
    DEFAULTS.each do |attrs|
      next if SurveyOverlay.exists?(name: attrs[:name])

      SurveyOverlay.create!(attrs)
    end
  end

  def down
    SurveyOverlay.where(name: DEFAULTS.map { |d| d[:name] }).destroy_all
  end
end
