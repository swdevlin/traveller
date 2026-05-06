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
    json.partial! 'stellar_objects/stellar_object', stellar_object: obj
    json.moons obj.moons do |m|
      json.partial! 'stellar_objects/stellar_object', stellar_object: m
    end
  end
end
