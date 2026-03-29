class TerrestrialPlanet < StellarObject
  include GeneratorMappings
  include HasUwp
  include NormalizesPlanetaryData

  after_initialize :set_default_data
  after_initialize :normalize_data_types
  before_validation :normalize_data_types

  validates :orbit, presence: true, if: -> { orbiting_id.present? }
  validates :size_code, presence: true
  validates :atmosphere_code, presence: true
  validates :hydrographics_code, presence: true

  generator_data_map(
    albedo: 'albedo',
    period: 'period',
    temperature: 'meanTemperature',
    density: 'density',
    gravity: 'gravity',
    axial_tilt: 'axialTilt',
    greenhouse: 'greenhouse',
    retrograde: 'retrograde',
    biomass_rating: 'biomassRating',
    biocomplexity_rating: 'biocomplexityCode',
    biodiversity_rating: 'biodiversityRating',
    compatibility_rating: 'compatibilityRating',
    extinct_sophont: 'extinctSophont',
    native_sophont: 'nativeSophont',
    rotation: 'rotation',
    resource_rating: 'resourceRating',
    atmosphere: 'atmosphere',
    hydrographics: 'hydrographics',
    population: 'population',
    government_code: 'governmentCode',
    law_level_code: 'lawLevelCode',
    tech_level_code: 'techLevel',
    starport_code: 'starPort',
    tidal_lock: 'tidalLock',
    tidal_lock_note: 'tidalLockNote',
    twilight_zone: 'twilightZone',
    sidereal_day: 'siderealDay'
  )

  def orbit_type = 11

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity, :diameter, :mass, :size_code,
      :period, :rotation, :retrograde, :density, :gravity,
      :temperature, :axial_tilt, :albedo, :greenhouse,
      :native_sophont, :extinct_sophont, :biomass_rating,
      :biodiversity_rating, :biocomplexity_rating, :resource_rating,
      *uwp_attribute_names
    ]
  end

  private

  def set_default_data
    self.atmosphere ||= { 'code' => nil, 'taint' => { 'code' => nil } }
    self.hydrographics ||= { 'code' => nil, 'distribution' => nil, 'liquid' => nil }
    self.population ||= { 'code' => nil, 'concentrationRating' => nil, 'urbanizationPercentage' => nil, 'majorCities' => nil }
  end
end
