class PlanetoidBelt < StellarObject
  include GeneratorMappings

  API_DATA_MAP = {
    m_type: 'mType',
    s_type: 'sType',
    c_type: 'cType',
    o_type: 'oType',
    resource_rating: 'resourceRating',
    bulk: 'bulk',
    span: 'span'
  }.freeze

end
