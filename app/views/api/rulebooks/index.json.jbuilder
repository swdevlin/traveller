json.array! @rulebooks do |rulebook|
  json.id           rulebook.id
  json.title        rulebook.title
  json.short_title  rulebook.short_title
  json.edition      rulebook.edition
  json.category     rulebook.category
end
