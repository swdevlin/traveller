json.array! @jumps do |jump|
  json.id jump.id
  json.arrive_day jump.arrive_day
  json.arrive_year jump.arrive_year
  json.depart_day jump.depart_day
  json.depart_year jump.depart_year
  json.from_parsec_id jump.from_parsec_id
  json.to_parsec_id jump.to_parsec_id
  json.misjump jump.misjump?
  json.from_x jump.from_x
  json.from_y jump.from_y
  json.from_sector_name jump.from_sector_name
  json.from_hex_code ::HexAddressing.hex_address_from_coords(jump.from_x, jump.from_y, jump.from_sector_x, jump.from_sector_y)
  json.to_x jump.to_x
  json.to_y jump.to_y
  json.to_sector_name jump.to_sector_name
  json.to_hex_code ::HexAddressing.hex_address_from_coords(jump.to_x, jump.to_y, jump.to_sector_x, jump.to_sector_y)
  json.ship_id jump.ship_id
end
