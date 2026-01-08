class TerrestrialPlanet < StellarObject
  include GeneratorMappings

  generator_data_map(
    albedo: 'albedo',
    period: 'period',
    density: 'density',
    gravity: 'gravity',
    axial_tilt: 'axialTilt',
    greenhouse: 'greenhouse',
    retrograde: 'retrograde',
    biomass_rating: 'biomassRating',
  )

end
