json.extract! stellar_object,
              :id, :type, :name, :uwp, :notes, :size_code,
              :orbit, :orbit_x, :orbit_y, :orbit_sequence,
              :au, :mass, :diameter, :inclination, :eccentricity,
              :effective_hzco_deviation, :survey_index, :detect_si,
              :parsec_id, :star_system_id, :orbiting_id, :allegiance_id,
              :tidal_lock_target_id, :companion_id,
              :created_at, :updated_at

deep_snake = ->(val) {
  case val
  when Hash  then val.transform_keys { |k| k.to_s.underscore }.transform_values(&deep_snake)
  when Array then val.map(&deep_snake)
  else val
  end
}
stellar_object.data&.each { |key, value| json.set! key.to_s.underscore, deep_snake.call(value) }

star_system = StarSystem.find_by(id: stellar_object.star_system_id)
parsec = stellar_object.parsec || star_system&.parsec
subsector = parsec&.subsector
sector = parsec&.sector

json.hex parsec&.hex_code
json.star_system_name star_system&.display_name
json.subsector_name subsector&.name
json.sector_name sector&.name

if stellar_object.allegiance
  json.allegiance do
    json.code stellar_object.allegiance.code
    json.name stellar_object.allegiance.name
  end
end

json.orbit_type stellar_object.orbit_type if stellar_object.respond_to?(:orbit_type)
json.orbiting_name stellar_object.orbiting&.display_name

shadow_km = stellar_object.effective_jump_shadow_km
if shadow_km&.positive?
  shadow_source = stellar_object.effective_jump_shadow_source
  json.jump_shadow do
    json.distance_km shadow_km.round
    json.source_id shadow_source&.id
    json.source_name shadow_source&.display_name
    json.travel_times do
      (1..6).each { |g| json.set! "#{g}g", flip_burn_travel_time_hours(shadow_km, g)&.round(2) }
    end
  end
end

json.star_system_map_url signed_map_url(map_star_system_path(star_system)) if star_system
json.url stellar_object_url(stellar_object, format: :json)

if stellar_object.is_a?(HasUwp)
  json.partial! 'stellar_objects/uwp_details', stellar_object: stellar_object
end
