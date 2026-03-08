json.partial! 'api/solar_system', star_system: @star_system

primary = @star_system.primary_star
mw = @star_system.main_world

if mw
  json.main_world do
    json.name mw.name
    json.uwp  mw.uwp
  end
else
  json.main_world nil
end

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
