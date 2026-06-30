module HasUwp
  extend ActiveSupport::Concern

  module AtmosphereAccessors
    def atmosphere
      Atmosphere.from_hash(data&.dig('atmosphere'))
    end

    def atmosphere=(value)
      self.data ||= {}
      self.data = data.merge('atmosphere' => value.is_a?(Atmosphere) ? value.to_h : value)
    end
  end

  included do
    prepend AtmosphereAccessors
    before_validation :normalize_uwp_attributes
    before_validation :sync_uwp, if: :uwp_inputs_changed?
  end

  def atmosphere_code          = atmosphere&.code
  def atmosphere_composition   = atmosphere&.composition
  def atmosphere_taint_code    = atmosphere&.taint_code.presence
  def atmosphere_taint_severity  = atmosphere&.taint_severity.presence
  def atmosphere_taint_persistence = atmosphere&.taint_persistence.presence
  def atmosphere_hazard_code   = atmosphere&.hazard_code.presence

  def atmosphere_code=(val)
    atm = atmosphere || Atmosphere.new
    atm.code = val.present? ? val.to_i : nil
    self.atmosphere = atm
  end

  def atmosphere_composition=(val)
    atm = atmosphere || Atmosphere.new
    atm.composition = val.presence
    self.atmosphere = atm
  end

  def atmosphere_taint_code=(val)
    atm = atmosphere || Atmosphere.new
    atm.taint_code = val.presence || ''
    atm.taint_subtype = Atmosphere::TAINT_SUBTYPES[val] || ''
    self.atmosphere = atm
  end

  def atmosphere_taint_severity=(val)
    atm = atmosphere || Atmosphere.new
    atm.taint_severity = val.present? ? val.to_i : 0
    self.atmosphere = atm
  end

  def atmosphere_taint_persistence=(val)
    atm = atmosphere || Atmosphere.new
    atm.taint_persistence = val.present? ? val.to_i : 0
    self.atmosphere = atm
  end

  def atmosphere_hazard_code=(val)
    atm = atmosphere || Atmosphere.new
    atm.hazard_code = val.presence
    self.atmosphere = atm
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

  def population_concentration_rating
    population&.dig('concentrationRating')
  end

  def population_concentration_rating=(val)
    self.population = (population || {}).merge('concentrationRating' => val.present? ? val.to_i : nil)
  end

  def population_urbanization_percentage
    population&.dig('urbanizationPercentage')
  end

  def population_urbanization_percentage=(val)
    self.population = (population || {}).merge('urbanizationPercentage' => val.present? ? val.to_i : nil)
  end

  def population_major_cities
    population&.dig('majorCities')
  end

  def population_major_cities=(val)
    self.population = (population || {}).merge('majorCities' => val.present? ? val.to_i : nil)
  end

  def population_cohesion              = population&.dig('cohesion')
  def population_diversity             = population&.dig('diversity')
  def population_militancy             = population&.dig('militancy')
  def population_symbology             = population&.dig('symbology')
  def population_uniqueness            = population&.dig('uniqueness')
  def population_xenophilia            = population&.dig('xenophilia')
  def population_expansionism          = population&.dig('expansionism')
  def population_progressiveness       = population&.dig('progressiveness')
  def population_major_city_population = population&.dig('majorCityPopulation')

  def government_code
    government&.dig('code')
  end

  def government_code=(val)
    self.government = (government || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def government_authority      = government&.dig('authority')
  def government_centralisation = government&.dig('centralisation')
  def government_judicial       = government&.dig('structure', 'judicial')
  def government_executive      = government&.dig('structure', 'executive')
  def government_legislative    = government&.dig('structure', 'legislative')

  def government_authority=(val)
    self.government = (government || {}).merge('authority' => val.presence)
  end

  def government_centralisation=(val)
    self.government = (government || {}).merge('centralisation' => val.presence)
  end

  def government_judicial=(val)
    structure = (government&.dig('structure') || {})
    self.government = (government || {}).merge('structure' => structure.merge('judicial' => val.presence))
  end

  def government_executive=(val)
    structure = (government&.dig('structure') || {})
    self.government = (government || {}).merge('structure' => structure.merge('executive' => val.presence))
  end

  def government_legislative=(val)
    structure = (government&.dig('structure') || {})
    self.government = (government || {}).merge('structure' => structure.merge('legislative' => val.presence))
  end

  def law_level_code
    law_level&.dig('code')
  end

  def law_level_code=(val)
    self.law_level = (law_level || {}).merge('code' => val.present? ? val.to_i : nil)
  end

  def law_level_private_law        = law_level&.dig('privateLaw')
  def law_level_criminal_law       = law_level&.dig('criminalLaw')
  def law_level_economic_law       = law_level&.dig('economicLaw')
  def law_level_personal_rights    = law_level&.dig('personalRights')
  def law_level_weapons_and_armour = law_level&.dig('weaponsAndArmour')
  def law_level_uniformity         = law_level&.dig('uniformity')
  def law_level_judicial_system    = law_level&.dig('judicialSystem')
  def law_level_death_penalty      = law_level&.dig('deathPenalty')
  def law_level_presumed_innocence = law_level&.dig('presumedInnocence')
  def law_level_econometric_infractions_administrative = law_level&.dig('econometricInfractionsAdministrative')

  def law_level_weapons_and_armour=(val)
    self.law_level = (law_level || {}).merge('weaponsAndArmour' => val.present? ? val.to_i : nil)
  end

  def law_level_criminal_law=(val)
    self.law_level = (law_level || {}).merge('criminalLaw' => val.present? ? val.to_i : nil)
  end

  def law_level_economic_law=(val)
    self.law_level = (law_level || {}).merge('economicLaw' => val.present? ? val.to_i : nil)
  end

  def law_level_private_law=(val)
    self.law_level = (law_level || {}).merge('privateLaw' => val.present? ? val.to_i : nil)
  end

  def law_level_personal_rights=(val)
    self.law_level = (law_level || {}).merge('personalRights' => val.present? ? val.to_i : nil)
  end

  def law_level_uniformity=(val)
    self.law_level = (law_level || {}).merge('uniformity' => val.presence)
  end

  def law_level_judicial_system=(val)
    self.law_level = (law_level || {}).merge('judicialSystem' => val.presence)
  end

  def law_level_death_penalty=(val)
    self.law_level = (law_level || {}).merge('deathPenalty' => ActiveModel::Type::Boolean.new.cast(val))
  end

  def law_level_presumed_innocence=(val)
    self.law_level = (law_level || {}).merge('presumedInnocence' => ActiveModel::Type::Boolean.new.cast(val))
  end

  def law_level_econometric_infractions_administrative=(val)
    self.law_level = (law_level || {}).merge('econometricInfractionsAdministrative' => ActiveModel::Type::Boolean.new.cast(val))
  end

  def starport_code
    data&.dig('starport_code')
  end

  def starport_code=(val)
    self.data = (data || {}).merge('starport_code' => val.presence)
  end

  def tech_level_code
    data&.dig('tech_level', 'code')
  end

  def tech_level_code=(value)
    self.data ||= {}
    self.data['tech_level'] ||= {}
    self.data['tech_level']['code'] = value.presence ? value.to_i : nil
  end

  TECH_LEVEL_CATEGORIES = %w[electronics energy land sea air space personal_military heavy_military manufacturing environmental medical].freeze

  TECH_LEVEL_CATEGORIES.each do |cat|
    define_method(:"tech_level_#{cat}") do
      data&.dig('tech_level', cat)
    end

    define_method(:"tech_level_#{cat}=") do |val|
      self.data ||= {}
      self.data['tech_level'] ||= {}
      self.data['tech_level'][cat] = val.present? ? val.to_i : nil
    end
  end

  module ClassMethods
    def uwp_attribute_names
      [
        :atmosphere_code, :atmosphere_composition,
        :atmosphere_taint_code, :atmosphere_taint_severity, :atmosphere_taint_persistence,
        :atmosphere_hazard_code,
        :hydrographics_code, :hydrographics_liquid, :hydrographics_distribution,
        :population_code, :population_concentration_rating, :population_urbanization_percentage, :population_major_cities,
        :government_code, :government_authority, :government_centralisation,
        :government_judicial, :government_executive, :government_legislative,
        :law_level_code, :law_level_weapons_and_armour, :law_level_criminal_law, :law_level_economic_law,
        :law_level_private_law, :law_level_personal_rights, :law_level_uniformity, :law_level_judicial_system,
        :law_level_death_penalty, :law_level_presumed_innocence, :law_level_econometric_infractions_administrative,
        :starport_code,
        :tech_level_code,
        :tech_level_electronics, :tech_level_energy, :tech_level_land, :tech_level_sea,
        :tech_level_air, :tech_level_space, :tech_level_personal_military, :tech_level_heavy_military,
        :tech_level_manufacturing, :tech_level_medical, :tech_level_environmental
      ]
    end
  end

  def world_trade_number
    data&.dig('economics', 'worldTradeNumber')
  end

  def importance
    data&.dig('economics', 'importance')
  end

  def per_capita_gwp
    data&.dig('economics', 'perCapitaGWP')
  end

  def total_gwp
    data&.dig('economics', 'totalGWP')
  end

  def efficiency
    data&.dig('economics', 'efficiency')
  end

  def labour_factor
    data&.dig('economics', 'labourFactor')
  end

  def resource_units
    data&.dig('economics', 'resourceUnits')
  end

  def infrastructure
    data&.dig('economics', 'infrastructure')
  end

  def resource_factor
    data&.dig('economics', 'resourceFactor')
  end

  def development_score
    data&.dig('economics', 'developmentScore')
  end

  def inequality_rating
    data&.dig('economics', 'inequalityRating')
  end

  def tariff_rate
    data&.dig('economics', 'tariffs', 'rate')
  end

  def tariff_regime
    data&.dig('economics', 'tariffs', 'regime')
  end

  private

  def sync_uwp
    self.uwp = [
      starport_code || 'X',
      size_code || '0',
      HexDigit.hex_digit(atmosphere_code),
      HexDigit.hex_digit(hydrographics_code),
      HexDigit.hex_digit(population_code),
      HexDigit.hex_digit(government_code),
      HexDigit.hex_digit(law_level_code),
      '-',
      HexDigit.hex_digit(tech_level_code)
    ].join
  end

  def normalize_uwp_attributes
    self.law_level_code = law_level_code.to_i if law_level_code.present?
  end

  def uwp_inputs_changed?
    will_save_change_to_size_code? || will_save_change_to_data?
  end
end
