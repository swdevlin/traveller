json.partial! 'api/solar_system', star_system: star_system
json.map_url signed_map_url(map_star_system_path(star_system))

player_visible = @is_referee || star_system.known? || star_system.survey_index >= 10

json.known star_system.known?
json.reference_url player_visible ? star_system.effective_reference_url(current_campaign) : nil
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
    json.berthing_cost mw.respond_to?(:berthing_cost) ? mw.berthing_cost : nil
    json.refined_fuel_cost mw.respond_to?(:refined_fuel_cost) ? mw.refined_fuel_cost : nil
    json.unrefined_fuel_cost mw.respond_to?(:unrefined_fuel_cost) ? mw.unrefined_fuel_cost : nil
  end
else
  json.main_world nil
end

if primary
  parsec = star_system.parsec
  render_context = {
    star_system: star_system,
    parsec: parsec,
    subsector: parsec&.subsector,
    sector: parsec&.sector,
    governments_by_code: Government.all.index_by(&:code),
    law_levels_by_code: LawLevel.all.index_by(&:code),
    tech_levels_by_code: TechLevel.all.index_by(&:code),
    city_counts_by_stellar_object_id: star_system.city_counts_by_stellar_object_id
  }

  json.primary_star do
    json.partial! 'api/star_body', star: primary, render_context: render_context
  end
else
  json.primary_star nil
end
