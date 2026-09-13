class TerrestrialPlanet < StellarObject
  include HasUwp
  include NormalizesPlanetaryData
  include HasPlanetaryBodyAttributes

  after_initialize :set_default_data

  validates :orbit, presence: true, if: -> { orbiting_id.present? }
  validates :atmosphere_code, presence: true
  validates :hydrographics_code, presence: true

  def orbit_type = 11

  private

  def set_default_data
    self.atmosphere ||= Atmosphere.new
    self.hydrographics ||= Hydrographics.new
    self.population ||= { 'code' => nil, 'concentrationRating' => nil, 'urbanizationPercentage' => nil, 'majorCities' => nil }
  end
end
