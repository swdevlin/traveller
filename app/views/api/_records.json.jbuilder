# Survey Records (player_notes) are always served; Classified Records (referee_notes) only to the referee, and their keys
# are omitted otherwise so their existence isn't revealed. Pass `visible: false` to withhold both. The `_html` variants
# are sanitised Markdown renders so every client shows the records identically.
visible = local_assigns.fetch(:visible, true)
json.tags(visible && Current.referee_access? && record.respond_to?(:tag_names) ? record.tag_names : [])
survey = visible ? record.player_notes.presence : nil

json.survey_records survey
json.survey_records_html survey && render_markdown(survey)

if visible && Current.referee_access?
  classified = record.referee_notes.presence
  json.classified_records classified
  json.classified_records_html classified && render_markdown(classified)
end
