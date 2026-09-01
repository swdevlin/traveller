json.array! @regions do |region|
  json.id             region.id
  json.name           region.name
  json.label          region.label
  json.colour         region.colour&.delete_prefix('#')
  json.border_colour  region.border_colour&.delete_prefix('#')
  json.player_visible region.player_visible?
  json.label_x        region.label_x
  json.label_y        region.label_y

  visible = region.region_parsecs.select { |rp| @x_range.cover?(rp.parsec.x) && @y_range.cover?(rp.parsec.y) }
  json.hexes visible.map { |rp| { x: rp.parsec.x, y: rp.parsec.y } }
  json.border_hexes visible.select(&:border?).sort_by(&:position).map { |rp| { x: rp.parsec.x, y: rp.parsec.y } }
end
