json.array! @groups do |group|
  json.rulebook_id group.rulebook.id
  json.title group.rulebook.title
  json.short_title group.rulebook.short_title
  json.edition group.rulebook.edition
  json.category group.rulebook.category
  json.total_matches group.total_matches
  json.relevant_matches group.relevant_matches
  json.hits group.hits, partial: 'rulebook_search/hit', as: :hit
  json.low_relevance_hits group.low_relevance_hits, partial: 'rulebook_search/hit', as: :hit
end
