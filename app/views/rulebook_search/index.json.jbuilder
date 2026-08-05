json.array! @groups do |group|
  json.rulebook_id group.rulebook.id
  json.title group.rulebook.title
  json.short_title group.rulebook.short_title
  json.edition group.rulebook.edition
  json.category group.rulebook.category
  json.total_matches group.total_matches
  json.hits group.hits do |hit|
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
  end
end
