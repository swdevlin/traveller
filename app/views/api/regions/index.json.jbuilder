json.array! @regions do |region|
  json.id      region.id
  json.name    region.name
  json.colour  region.colour&.delete_prefix('#')
  json.label_x region.label_x
  json.label_y region.label_y

  fill_parsecs = region.region_parsecs.select(&:fill?).map(&:parsec)
  json.hexes fill_parsecs do |parsec|
    json.x parsec.x
    json.y parsec.y
  end
end
