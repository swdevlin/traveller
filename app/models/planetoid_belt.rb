class PlanetoidBelt < StellarObject
  include GeneratorMappings

  def diameter
    0
  end

  generator_data_map(
    m_type: 'mType',
    s_type: 'sType',
    c_type: 'cType',
    o_type: 'oType',
    resource_rating: 'resourceRating',
    bulk: 'bulk',
    span: 'span',
    temperature: 'meanTemperature',
    retrograde: 'retrograde',
    period: 'period',
    significant_bodies: 'significantBodies'
  )
end
