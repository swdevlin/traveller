parsec = star_system.parsec
sector = parsec.sector

json.(star_system, :id, :name, :survey_index, :gas_giant_count, :terrestrial_count, :belt_count)

json.sector_x    sector.x
json.sector_y    sector.y
json.sector_name sector.name
json.x           parsec.x - sector.x * 32 + 1
json.y           sector.y * 40 - parsec.y + 1
json.origin_x    parsec.x
json.origin_y    parsec.y
json.scan_points 0
json.allegiance  star_system.allegiance&.code
json.native_sophont  star_system.stellar_objects.any? { |o| o.data&.dig('native_sophont') }
json.extinct_sophont star_system.stellar_objects.any? { |o| o.data&.dig('extinct_sophont') }
json.star_count  star_system.stars.size
json.bases       star_system.facilities_string
json.remarks     star_system.trade_codes_string

json.stars star_system.stars do |s|
  json.colour          s.colour
  json.stellar_class   s.stellar_class
  json.stellar_type    s.stellar_type
  json.stellar_subtype s.stellar_subtype
  json.luminosity      s.luminosity
end
