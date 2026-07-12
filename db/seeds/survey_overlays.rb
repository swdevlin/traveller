[
  { name: 'Native Sophonts', colour: '#22c55e',
    rule_data: { groups: [[{ field: 'native_sophont', operator: 'eq', negate: false, values: ['true'] }]] } },
  { name: 'Extinct Sophonts', colour: '#6b7280',
    rule_data: { groups: [[{ field: 'extinct_sophont', operator: 'eq', negate: false, values: ['true'] }]] } }
].each do |attrs|
  SurveyOverlay.find_or_create_by!(name: attrs[:name]) do |survey_overlay|
    survey_overlay.colour    = attrs[:colour]
    survey_overlay.enabled   = true
    survey_overlay.rule_data = attrs[:rule_data]
  end
end
