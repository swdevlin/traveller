parsec = star_system.parsec
sector = parsec.sector

json.id                star_system.id
json.name              star_system.name.presence || ''
json.survey_index      star_system.survey_index
json.gas_giant_count   star_system.gas_giant_count
json.terrestrial_count star_system.terrestrial_count
json.belt_count        star_system.belt_count

json.sector_x    sector.x
json.sector_y    sector.y
json.sector_name sector.name
json.x           parsec.x - sector.x * 32 + 1
json.y           sector.y * 40 - parsec.y + 1
json.origin_x    parsec.x
json.origin_y    parsec.y
json.scan_points 0
json.allegiance  star_system.allegiance&.code
json.native_sophont  star_system.native_sophont
json.extinct_sophont star_system.extinct_sophont
json.star_count  star_system.stars.size
json.bases       star_system.facilities_string
json.remarks     star_system.trade_codes_string
