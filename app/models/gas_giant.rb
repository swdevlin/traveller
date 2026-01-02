class GasGiant < StellarObject
  include GeneratorMappings

  API_DATA_MAP = {
    code: 'code',
    has_ring: 'hasRing',
  }.freeze

end
