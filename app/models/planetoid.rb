class Planetoid < StellarObject
  include HasUwp
  include NormalizesPlanetaryData
  include HasPlanetaryBodyAttributes
  include HasPlanetMap

  def orbit_type = 13

  store_accessor :data, :planetoid_belt_id
end
