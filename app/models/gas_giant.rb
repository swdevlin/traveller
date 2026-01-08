class GasGiant < StellarObject
  include GeneratorMappings

  generator_data_map(
    diameter: 'diameter',
    atmosphere: 'atmosphere',
    hydrographics: 'hydrographics'
  )
end
