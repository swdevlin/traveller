# Notes are rendered from Markdown to sanitised HTML here so every client shows them identically.
json.id sophont.id
json.name sophont.name
json.reference_url sophont.effective_reference_url(current_campaign)
json.picture_url(sophont.picture.attached? ? signed_map_url(picture_sophont_path(sophont)) : nil)
json.player_notes sophont.player_notes
json.player_notes_html sophont.player_notes.present? ? render_markdown(sophont.player_notes) : nil
# Referee notes never leave the server for anyone but the campaign's referee.
json.referee_notes_html((Current.owns_campaign? && sophont.referee_notes.present?) ? render_markdown(sophont.referee_notes) : nil)
json.referee_notes((Current.owns_campaign? && sophont.referee_notes.present?) ? sophont.referee_notes : nil)
