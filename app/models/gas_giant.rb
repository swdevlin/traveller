class GasGiant < StellarObject
  include GeneratorMappings

  generator_data_map(
    diameter: 'diameter',
    code: 'code',
    period: 'period',
  )
end
