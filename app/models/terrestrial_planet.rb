class TerrestrialPlanet < StellarObject
  include GeneratorMappings

  after_initialize :set_default_data
  after_initialize :normalize_data_types
  before_validation :normalize_data_types

  validates :orbit, presence: true, if: -> { orbiting_star_id.present? }
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
  )

  def atmosphere_code
    atmosphere&.dig('code')
  end

  def atmosphere_code=(val)
    self.atmosphere = (atmosphere || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def atmosphere_composition
    atmosphere&.dig('composition')
  end

  def atmosphere_composition=(val)
    self.atmosphere = (atmosphere || {}).merge('composition' => val.presence)
  end

  def hydrographics_code
    hydrographics&.dig('code')
  end

  def hydrographics_code=(val)
    self.hydrographics = (hydrographics || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def hydrographics_liquid
    hydrographics&.dig('liquid')
  end

  def hydrographics_liquid=(val)
    self.hydrographics = (hydrographics || {}).merge('liquid' => val.presence)
  end

  def hydrographics_distribution
    hydrographics&.dig('distribution')
  end

  def hydrographics_distribution=(val)
    self.hydrographics = (hydrographics || {}).merge('distribution' => val.present? ? val.to_i : nil)
  end

  def population_code
    population&.dig('code')
  end

  def population_code=(val)
    self.population = (population || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity, :diameter, :mass, :size_code,
      :atmosphere_code, :atmosphere_composition,
      :hydrographics_code, :hydrographics_liquid, :hydrographics_distribution,
      :period, :rotation, :retrograde, :density, :gravity,
      :temperature, :axial_tilt, :albedo, :greenhouse,
      :native_sophont, :extinct_sophont, :biomass_rating,
      :biodiversity_rating, :biocomplexity_rating, :resource_rating,
      :population_code, :government_code, :law_level_code
    ]
  end

  private

  def set_default_data
    self.atmosphere ||= { 'code' => nil, 'taint' => { 'code' => nil } }
    self.hydrographics ||= { 'code' => nil, 'distribution' => nil, 'liquid' => nil }
    self.population ||= { 'code' => nil, 'concentrationRating' => nil }
  end

  def normalize_data_types
    self.period = period.to_f if period.present?
    self.rotation = rotation.to_f if rotation.present?
    self.density = density.to_f if density.present?
    self.gravity = gravity.to_f if gravity.present?
    self.temperature = temperature.to_f if temperature.present?
    self.axial_tilt = axial_tilt.to_f if axial_tilt.present?
    self.albedo = albedo.to_f if albedo.present?
    self.greenhouse = greenhouse.to_f if greenhouse.present?
    self.biomass_rating = biomass_rating.to_i if biomass_rating.present?
    self.biodiversity_rating = biodiversity_rating.to_i if biodiversity_rating.present?
    self.resource_rating = resource_rating.to_i if resource_rating.present?
    self.government_code = government_code.to_i if government_code.present?
    self.law_level_code = law_level_code.to_i if law_level_code.present?
    self.retrograde = ActiveModel::Type::Boolean.new.cast(retrograde)
    self.native_sophont = ActiveModel::Type::Boolean.new.cast(native_sophont)
    self.extinct_sophont = ActiveModel::Type::Boolean.new.cast(extinct_sophont)
  end
end
