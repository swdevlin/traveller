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

  module TechLevelAccessors
    def tech_level
      Technology.from_hash(data&.dig('tech_level'))
    end

    def tech_level=(value)
      self.data ||= {}
      self.data = data.merge('tech_level' => value.is_a?(Technology) ? value.to_h : value)
    end
  end

  included do
    prepend AtmosphereAccessors
    prepend HydrographicsAccessors
    prepend LegalSystemAccessors
    prepend GovernanceAccessors
    prepend TechLevelAccessors
    has_many :cities, foreign_key: :stellar_object_id, inverse_of: :stellar_object, dependent: :destroy
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

  def no_population?
    !(population_code.present? && population_code.to_i > 0)
  end

  def no_government?
    no_population? && !(government_code.present? && government_code.to_i > 0)
  end

  def no_law_level?
    no_population? && !(law_level_code.present? && law_level_code.to_i > 0)
  end

  def no_tech_level?
    no_population? && !(tech_level_code.present? && tech_level_code.to_i > 0)
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

  def total_urban_population
    population&.dig('totalUrbanPopulation') || data&.dig('total_urban_population')
  end

  def census_population
    population&.dig('censusPopulation')
  end

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

  BERTHING_COST_TABLE = {
    'A' => { dice: 1, multiplier: 1000, fuel: :refined },
    'B' => { dice: 1, multiplier: 500,  fuel: :refined },
    'C' => { dice: 1, multiplier: 100,  fuel: :unrefined },
    'D' => { dice: 1, multiplier: 10,   fuel: :unrefined },
    'E' => { dice: 0, multiplier: 0,    fuel: :none },
    'X' => { dice: 0, multiplier: 0,    fuel: :none }
  }.freeze

  DEFAULT_REFINED_FUEL_COST = 500
  DEFAULT_UNREFINED_FUEL_COST = 100

  def berthing_cost
    data&.dig('berthing_cost')
  end

  def berthing_cost=(val)
    self.data = (data || {}).merge('berthing_cost' => val.presence)
  end

  def refined_fuel_cost
    data&.dig('refined_fuel_cost')
  end

  def refined_fuel_cost=(val)
    self.data = (data || {}).merge('refined_fuel_cost' => val.presence)
  end

  def unrefined_fuel_cost
    data&.dig('unrefined_fuel_cost')
  end

  def unrefined_fuel_cost=(val)
    self.data = (data || {}).merge('unrefined_fuel_cost' => val.presence)
  end

  # Assigns berthing/fuel costs from the starport class per the standard
  # Traveller berthing-cost table (WBH p. 257). Berthing cost is rolled;
  # fuel costs are flat defaults, present only when that fuel grade is sold.
  def assign_starport_costs(roller: DiceRoller.new)
    entry = BERTHING_COST_TABLE.fetch(starport_code, BERTHING_COST_TABLE['X'])
    self.berthing_cost = entry[:dice].zero? ? nil : roller.roll(n: entry[:dice], d: 6, note: 'Berthing cost') * entry[:multiplier]
    self.refined_fuel_cost = entry[:fuel] == :refined ? DEFAULT_REFINED_FUEL_COST : nil
    self.unrefined_fuel_cost = entry[:fuel] == :none ? nil : DEFAULT_UNREFINED_FUEL_COST
  end

  def tech_level_code = tech_level&.code

  def tech_level_code=(val)
    tl = tech_level || Technology.new
    tl.code = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_energy           = tech_level&.energy
  def tech_level_electronics      = tech_level&.electronics
  def tech_level_manufacturing    = tech_level&.manufacturing
  def tech_level_medical          = tech_level&.medical
  def tech_level_environmental    = tech_level&.environmental
  def tech_level_land             = tech_level&.land
  def tech_level_sea              = tech_level&.sea
  def tech_level_air              = tech_level&.air
  def tech_level_space            = tech_level&.space
  def tech_level_personal_military = tech_level&.personal_military
  def tech_level_heavy_military   = tech_level&.heavy_military

  def tech_level_energy=(val)
    tl = tech_level || Technology.new
    tl.energy = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_electronics=(val)
    tl = tech_level || Technology.new
    tl.electronics = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_manufacturing=(val)
    tl = tech_level || Technology.new
    tl.manufacturing = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_medical=(val)
    tl = tech_level || Technology.new
    tl.medical = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_environmental=(val)
    tl = tech_level || Technology.new
    tl.environmental = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_land=(val)
    tl = tech_level || Technology.new
    tl.land = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_sea=(val)
    tl = tech_level || Technology.new
    tl.sea = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_air=(val)
    tl = tech_level || Technology.new
    tl.air = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_space=(val)
    tl = tech_level || Technology.new
    tl.space = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_personal_military=(val)
    tl = tech_level || Technology.new
    tl.personal_military = val.present? ? val.to_i : nil
    self.tech_level = tl
  end

  def tech_level_heavy_military=(val)
    tl = tech_level || Technology.new
    tl.heavy_military = val.present? ? val.to_i : nil
    self.tech_level = tl
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
        :berthing_cost, :refined_fuel_cost, :unrefined_fuel_cost,
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

  def image_name
    return nil unless data.is_a?(Hash)

    atmo_data  = data['atmosphere'] || {}
    atmo       = atmo_data['code'].to_i
    hydro      = (data.dig('hydrographics', 'code') || 0).to_i
    temp       = data['temperature']&.to_f
    density    = atmo_data['density'].to_s
    taint_code = atmo_data.dig('taint', 'code').to_s.upcase

    is_sparse = density.start_with?('Trace', 'Thin', 'Very Thin')

    return 'unusual'    if atmo == 10
    return 'corrosive'  if atmo == 11
    return 'insidious'  if atmo == 12
    return 'dense'      if atmo == 13
    return 'low'        if atmo == 14
    return 'unusual'    if atmo == 15
    return 'helium'     if atmo == 16
    return 'hydrogen'   if atmo == 17
    return 'biological' if taint_code == 'B'

    if hydro == 0
      return 'hot_rockball' if temp && temp > 473.15
      return 'trace'        if is_sparse
      return 'desert'
    end

    return 'molten' if temp && temp >= 673.15
    return 'ice'    if temp && temp < 263.15

    if atmo <= 9
      return 'waterworld'       if hydro == 10
      return "tp_#{hydro * 10}" if hydro >= 1 && hydro <= 9
    end

    nil
  end

  def normalize_uwp_attributes
    self.law_level_code = law_level_code.to_i if law_level_code.present?
  end

  def uwp_inputs_changed?
    will_save_change_to_size_code? || will_save_change_to_data?
  end
end
