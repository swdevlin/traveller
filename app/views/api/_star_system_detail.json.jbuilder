json.partial! 'api/solar_system', star_system: star_system
json.map_url signed_map_url(map_star_system_path(star_system))

player_visible = @is_referee || star_system.known? || star_system.survey_index >= 10

json.known star_system.known?
json.bases(player_visible ? star_system.facilities.to_a.sort_by(&:code) : []) do |facility|
  json.code facility.code
  json.name facility.name
  json.icon_class facility.icon_class.presence
end
json.trade_codes player_visible ? star_system.trade_codes.to_a.sort_by(&:code).map(&:code) : []

primary = star_system.primary_star
mw = star_system.main_world

if mw
  json.main_world do
    json.name mw.name
    json.uwp  mw.uwp
    json.gravity mw.gravity
    json.temperature mw.temperature
    json.native_sophont mw.native_sophont || false
    json.extinct_sophont mw.extinct_sophont || false
    json.census_population mw.respond_to?(:census_population) ? mw.census_population : nil
    json.survival_requirement atmosphere_survival_requirement(
      mw.respond_to?(:atmosphere_code) ? mw.atmosphere_code : nil,
      tainted: mw.respond_to?(:atmosphere) && mw.atmosphere&.tainted?
    )
    json.jump_shadow mw.effective_jump_shadow_km
  end
else
  json.main_world nil
end

if primary
  json.primary_star do
    json.partial! 'api/star_body', star: primary
  end
else
  json.primary_star nil
end
