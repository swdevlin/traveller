json.id     @subsector.id
json.name   @subsector.name
json.x      @subsector.x
json.y      @subsector.y
json.letter ('A'.ord + (@subsector.y - 1) * 4 + (@subsector.x - 1)).chr

json.sector do
  json.id   @subsector.sector.id
  json.name @subsector.sector.name
  json.x    @subsector.sector.x
  json.y    @subsector.sector.y
end

json.star_systems @star_systems do |star_system|
  json.partial! 'api/solar_system', star_system: star_system

  json.hex star_system.parsec.subsector_hex_code

  mw = star_system.main_world
  if mw
    json.main_world do
      json.name mw.name
      json.uwp  mw.uwp
    end
  else
    json.main_world nil
  end

  primary = star_system.primary_star
  if primary
    json.primary_star do
      json.colour          primary.colour
      json.stellar_class   primary.stellar_class
      json.stellar_type    primary.stellar_type
      json.stellar_subtype primary.stellar_subtype
      json.luminosity      primary.luminosity
    end
  else
    json.primary_star nil
  end
end
