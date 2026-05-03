json.colour                   star.colour
json.stellar_class            star.stellar_class
json.stellar_type             star.stellar_type
json.stellar_subtype          star.stellar_subtype
json.luminosity               star.luminosity
json.hzco                     star.hzco
json.minimum_allowable_orbit  star.minimum_allowable_orbit
json.jump_shadow              star.jump_shadow
json.is_protostar             star.is_protostar
json.temperature              star.temperature
json.age                      star.age
json.period                   star.period
json.baseline                 star.baseline
json.spread                   star.spread
json.scan_points              star.scan_points
json.diameter                 star.diameter
json.mass                     star.mass
json.au                       star.au || 0
json.orbit                    star.orbit || 0.0
json.orbit_sequence           star.orbit_sequence || ''
json.eccentricity             star.eccentricity || 0.0
json.inclination              star.inclination || 0.0
json.effective_hzco_deviation star.effective_hzco_deviation || 0.0
json.orbit_position do
  json.x star.orbit_x || 0.0
  json.y star.orbit_y || 0.0
end
json.orbit_type star.orbiting_id.nil? ? 0 : 1
json.safe_jump_time star.safe_jump_time

companion = star.companion
if companion
  json.companion do
    json.partial! 'api/star_body', star: companion
  end
else
  json.companion nil
end

all_objects = (star.stellar_objects.reject { |o| o.is_a?(Moon) } + star.secondary_stars)
              .sort_by { |o| o.orbit.to_f }

json.stellar_objects all_objects do |obj|
  if obj.is_a?(Star)
    json.type 'Star'
    json.partial! 'api/star_body', star: obj
  else
    json.merge! obj.data.except('build_log')
    json.type                     obj.type
    json.orbit                    obj.orbit || 0.0
    json.eccentricity             obj.eccentricity || 0.0
    json.inclination              obj.inclination || 0.0
    json.effective_hzco_deviation obj.effective_hzco_deviation || 0.0
    json.orbit_sequence           obj.orbit_sequence || ''
    json.au                       obj.au || 0.0
    json.diameter                 obj.diameter
    json.mass                     obj.mass
    json.uwp                      obj.uwp
    json.size                     obj.size_code
    json.orbit_position do
      json.x obj.orbit_x || 0.0
      json.y obj.orbit_y || 0.0
    end
    json.jump_shadow obj.effective_jump_shadow_km
    obj_shadow_source = obj.effective_jump_shadow_source
    json.jump_shadow_source obj_shadow_source ? { id: obj_shadow_source.id, name: obj_shadow_source.display_name } : nil
    json.orbit_type         obj.orbit_type
    json.retrograde     obj.retrograde || false if obj.respond_to?(:retrograde)
    json.axial_tilt     obj.axial_tilt if obj.is_a?(TerrestrialPlanet) || obj.is_a?(Planetoid) || obj.is_a?(GasGiant)

    json.moons obj.moons do |m|
      json.merge! m.data.except('build_log')
      json.orbit                    m.orbit || 0.0
      json.eccentricity             m.eccentricity || 0.0
      json.inclination              m.inclination || 0.0
      json.effective_hzco_deviation m.effective_hzco_deviation || 0.0
      json.orbit_sequence           m.orbit_sequence || ''
      json.au                       m.au || 0.0
      json.diameter                 m.diameter
      json.mass                     m.mass
      json.uwp                      m.uwp
      json.size                     m.size_code
      json.orbit_position do
        json.x m.orbit_x || 0.0
        json.y m.orbit_y || 0.0
      end
      json.jump_shadow m.effective_jump_shadow_km
      m_shadow_source = m.effective_jump_shadow_source
      json.jump_shadow_source m_shadow_source ? { id: m_shadow_source.id, name: m_shadow_source.display_name } : nil
      json.axial_tilt         m.axial_tilt
    end
  end
end
