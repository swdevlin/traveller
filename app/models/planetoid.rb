class Planetoid < StellarObject
  include GeneratorMappings

  generator_data_map(
    albedo: 'albedo',
    temperature: 'meanTemperature',
    period: 'period',
    density: 'density',
    gravity: 'gravity',
    axial_tilt: 'axialTilt',
    greenhouse: 'greenhouse',
    retrograde: 'retrograde',
    biomass_rating: 'biomassRating',
    rotation: 'rotation'
  )
end
