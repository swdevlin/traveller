json.extract! stellar_object, :id, :orbit_x, :orbit_y, :Parsec_id, :SolarSystem_id, :inclination, :eccentricity, :orbit, :effective_hzco_deviation, :created_at, :updated_at
json.url stellar_object_url(stellar_object, format: :json)
