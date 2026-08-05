json.printed_page_label hit.rulebook_page.effective_printed_page_label
json.rank hit.rank
json.heading_segments hit.heading_segments do |segment|
  json.text segment.text
  json.highlighted segment.highlighted
end
json.excerpt_segments hit.excerpt_segments do |segment|
  json.text segment.text
  json.highlighted segment.highlighted
end
