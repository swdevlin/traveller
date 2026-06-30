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

  module HydrographicsAccessors
    def hydrographics
      Hydrographics.from_hash(data&.dig('hydrographics'))
    end

    def hydrographics=(value)
      self.data ||= {}
      self.data = data.merge('hydrographics' => value.is_a?(Hydrographics) ? value.to_h : value)
    end
  end

  module LegalSystemAccessors
    def law_level
      LegalSystem.from_hash(data&.dig('law_level'))
    end

    def law_level=(value)
      self.data ||= {}
      self.data = data.merge('law_level' => value.is_a?(LegalSystem) ? value.to_h : value)
    end
  end

  module GovernanceAccessors
    def government
      Governance.from_hash(data&.dig('government'))
    end

    def government=(value)
      self.data ||= {}
      self.data = data.merge('government' => value.is_a?(Governance) ? value.to_h : value)
    end
  end

  included do
    prepend AtmosphereAccessors
    prepend HydrographicsAccessors
    prepend LegalSystemAccessors
    prepend GovernanceAccessors
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

  def hydrographics_code          = hydrographics&.code
  def hydrographics_liquid        = hydrographics&.liquid
  def hydrographics_distribution  = hydrographics&.distribution

  def hydrographics_code=(val)
    hyd = hydrographics || Hydrographics.new
    hyd.code = val.present? ? val.to_i : nil
    self.hydrographics = hyd
  end

  def hydrographics_liquid=(val)
    hyd = hydrographics || Hydrographics.new
    hyd.liquid = val.presence
    self.hydrographics = hyd
  end

  def hydrographics_distribution=(val)
    hyd = hydrographics || Hydrographics.new
    hyd.distribution = val.present? ? val.to_i : nil
    self.hydrographics = hyd
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
    government&.code
  end

  def government_code=(val)
    gov = government || Governance.new
    gov.code = val.present? ? val.to_i : nil
    self.government = gov
  end

  def government_authority      = government&.authority
  def government_centralisation = government&.centralisation
  def government_judicial       = government&.judicial
  def government_executive      = government&.executive
  def government_legislative    = government&.legislative

  def government_authority=(val)
    gov = government || Governance.new
    gov.authority = val.presence
    self.government = gov
  end

  def government_centralisation=(val)
    gov = government || Governance.new
    gov.centralisation = val.presence
    self.government = gov
  end

  def government_judicial=(val)
    gov = government || Governance.new
    gov.judicial = val.presence
    self.government = gov
  end

  def government_executive=(val)
    gov = government || Governance.new
    gov.executive = val.presence
    self.government = gov
  end

  def government_legislative=(val)
    gov = government || Governance.new
    gov.legislative = val.presence
    self.government = gov
  end

  def law_level_code
    law_level&.code
  end

  def law_level_code=(val)
    ll = law_level || LegalSystem.new
    ll.code = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_private_law        = law_level&.private_law
  def law_level_criminal_law       = law_level&.criminal_law
  def law_level_economic_law       = law_level&.economic_law
  def law_level_personal_rights    = law_level&.personal_rights
  def law_level_weapons_and_armour = law_level&.weapons_and_armour
  def law_level_uniformity         = law_level&.uniformity
  def law_level_judicial_system    = law_level&.judicial_system
  def law_level_death_penalty      = law_level&.death_penalty
  def law_level_presumed_innocence = law_level&.presumed_innocence
  def law_level_econometric_infractions_administrative = law_level&.econometric_infractions_administrative

  def law_level_weapons_and_armour=(val)
    ll = law_level || LegalSystem.new
    ll.weapons_and_armour = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_criminal_law=(val)
    ll = law_level || LegalSystem.new
    ll.criminal_law = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_economic_law=(val)
    ll = law_level || LegalSystem.new
    ll.economic_law = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_private_law=(val)
    ll = law_level || LegalSystem.new
    ll.private_law = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_personal_rights=(val)
    ll = law_level || LegalSystem.new
    ll.personal_rights = val.present? ? val.to_i : nil
    self.law_level = ll
  end

  def law_level_uniformity=(val)
    ll = law_level || LegalSystem.new
    ll.uniformity = val.presence
    self.law_level = ll
  end

  def law_level_judicial_system=(val)
    ll = law_level || LegalSystem.new
    ll.judicial_system = val.presence
    self.law_level = ll
  end

  def law_level_death_penalty=(val)
    ll = law_level || LegalSystem.new
    ll.death_penalty = val
    self.law_level = ll
  end

  def law_level_presumed_innocence=(val)
    ll = law_level || LegalSystem.new
    ll.presumed_innocence = val
    self.law_level = ll
  end

  def law_level_econometric_infractions_administrative=(val)
    ll = law_level || LegalSystem.new
    ll.econometric_infractions_administrative = val
    self.law_level = ll
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
