json.array! @jumps do |jump|
  json.id jump.id
  json.arrive_day jump.arrive_day
  json.arrive_year jump.arrive_year
  json.depart_day jump.depart_day
  json.depart_year jump.depart_year
  json.from_parsec_id jump.from_parsec_id
  json.to_parsec_id jump.to_parsec_id
  json.misjump jump.misjump?
  json.from_x jump.from_parsec.x
  json.from_y jump.from_parsec.y
  json.to_x jump.to_parsec.x
  json.to_y jump.to_parsec.y
  json.ship_id jump.ship_id
end
