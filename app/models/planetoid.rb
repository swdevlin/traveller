class Planetoid < StellarObject
  include GeneratorMappings

  generator_data_map(
    albedo: 'albedo',
    temperature: 'temperature',
    period: 'period',
    density: 'density',
    gravity: 'gravity',
    axial_tilt: 'axialTilt',
    greenhouse: 'greenhouse',
    retrograde: 'retrograde',
    biomass_rating: 'biomassRating'
  )
end
