class TerrestrialPlanet < StellarObject
  include GeneratorMappings
  include HasUwpAttributes

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

  def self.permitted_params
    [
      :name, :notes, :orbit, :inclination, :eccentricity, :diameter, :mass, :size_code,
      :period, :rotation, :retrograde, :density, :gravity,
      :temperature, :axial_tilt, :albedo, :greenhouse,
      :native_sophont, :extinct_sophont, :biomass_rating,
      :biodiversity_rating, :biocomplexity_rating, :resource_rating,
      *uwp_permitted_params
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
    self.retrograde = ActiveModel::Type::Boolean.new.cast(retrograde)
    self.native_sophont = ActiveModel::Type::Boolean.new.cast(native_sophont)
    self.extinct_sophont = ActiveModel::Type::Boolean.new.cast(extinct_sophont)
  end
end
