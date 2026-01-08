class Star < StellarObject
  include GeneratorMappings

  generator_data_map(
    age: 'age',
    temperature: 'temperature',
    colour: 'colour',
    spread: 'spread',
    baseline: 'baseline',
    stellar_class: 'stellarClass',
    stellar_type: 'stellarType',
    stellar_subtype: 'subtype',
  )

  def spectral_classification
    "#{stellar_type}#{stellar_subtype} #{stellar_class}"
  end
end
