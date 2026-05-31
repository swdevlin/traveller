json.partial! 'api/solar_system', star_system: star_system
json.map_url signed_map_url(map_star_system_path(star_system))

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
    json.survival_requirement atmosphere_survival_requirement(
      mw.respond_to?(:atmosphere_code) ? mw.atmosphere_code : nil,
      tainted: mw.respond_to?(:atmosphere) && mw.atmosphere&.dig('taint', 'code').present?
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
