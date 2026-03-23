class Moon < StellarObject
  include GeneratorMappings
  include HasUwp

  after_initialize :normalize_data_types
  before_validation :normalize_data_types

  validates :size_code, inclusion: { in: StellarObject::SIZE_CODES }

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

  private

  def normalize_data_types
    self.period = period.presence&.to_f
    self.rotation = rotation.presence&.to_f
    self.density = density.presence&.to_f
    self.gravity = gravity.presence&.to_f
    self.temperature = temperature.presence&.to_f
    self.axial_tilt = axial_tilt.presence&.to_f
    self.albedo = albedo.presence&.to_f
    self.greenhouse = greenhouse.presence&.to_f
    self.biomass_rating = biomass_rating.presence&.to_i
    self.biodiversity_rating = biodiversity_rating.presence&.to_i
    self.resource_rating = resource_rating.presence&.to_i
    self.retrograde = ActiveModel::Type::Boolean.new.cast(retrograde)
    self.native_sophont = ActiveModel::Type::Boolean.new.cast(native_sophont)
    self.extinct_sophont = ActiveModel::Type::Boolean.new.cast(extinct_sophont)
  end
end
