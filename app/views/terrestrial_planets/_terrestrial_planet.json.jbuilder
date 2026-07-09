json.partial! 'stellar_objects/stellar_object', stellar_object: terrestrial_planet
json.extract! terrestrial_planet, :albedo, :period, :temperature, :density, :gravity, :axial_tilt, :greenhouse, :retrograde, :biomass_rating, :extinct_sophont, :native_sophont, :allegiance_id
