json.array! @regions do |region|
  json.id             region.id
  json.name           region.name
  json.colour         region.colour&.delete_prefix('#')
  json.border_colour  region.border_colour&.delete_prefix('#')
  json.player_visible region.player_visible?
  json.label_x        region.label_x
  json.label_y        region.label_y

  all_parsecs = region.region_parsecs.map(&:parsec)
  json.hexes all_parsecs do |parsec|
    json.x parsec.x
    json.y parsec.y
  end

  border_parsecs = region.border_parsecs_ordered.map(&:parsec)
  json.border_hexes border_parsecs do |parsec|
    json.x parsec.x
    json.y parsec.y
  end
end
