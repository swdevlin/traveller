class MarkdownPresenterBase
  include ActionView::Helpers::NumberHelper
  include JumpShadowMath

  ATMOSPHERE_DESCRIPTIONS = StellarObjectsHelper::ATMOSPHERE_DESCRIPTIONS
  ATMOSPHERE_SURVIVAL_REQUIREMENTS = StellarObjectsHelper::ATMOSPHERE_SURVIVAL_REQUIREMENTS
  HYDROGRAPHICS_DESCRIPTIONS = StellarObjectsHelper::HYDROGRAPHICS_DESCRIPTIONS
  HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS = StellarObjectsHelper::HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS
  TAINT_DESCRIPTIONS = StellarObjectsHelper::TAINT_DESCRIPTIONS
  TAINT_SEVERITY_DESCRIPTIONS = StellarObjectsHelper::TAINT_SEVERITY_DESCRIPTIONS
  TAINT_PERSISTENCE_DESCRIPTIONS = StellarObjectsHelper::TAINT_PERSISTENCE_DESCRIPTIONS
  HABITABILITY_RATING_DESCRIPTIONS = StellarObjectsHelper::HABITABILITY_RATING_DESCRIPTIONS
  RESOURCE_RATING_DESCRIPTIONS = StellarObjectsHelper::RESOURCE_RATING_DESCRIPTIONS
  BIOCOMPLEXITY_DESCRIPTIONS = StellarObjectsHelper::BIOCOMPLEXITY_DESCRIPTIONS
  POPULATION_RANGES = StellarObjectsHelper::POPULATION_RANGES
  CONCENTRATION_RATING_DESCRIPTIONS = StellarObjectsHelper::CONCENTRATION_RATING_DESCRIPTIONS
  LAW_UNIFORMITY_DESCRIPTIONS = StellarObjectsHelper::LAW_UNIFORMITY_DESCRIPTIONS
  LAW_JUDICIAL_SYSTEM_DESCRIPTIONS = StellarObjectsHelper::LAW_JUDICIAL_SYSTEM_DESCRIPTIONS
  GOVERNMENT_AUTHORITY_DESCRIPTIONS = StellarObjectsHelper::GOVERNMENT_AUTHORITY_DESCRIPTIONS
  GOVERNMENT_CENTRALISATION_DESCRIPTIONS = StellarObjectsHelper::GOVERNMENT_CENTRALISATION_DESCRIPTIONS
  GOVERNMENT_STRUCTURE_DESCRIPTIONS = StellarObjectsHelper::GOVERNMENT_STRUCTURE_DESCRIPTIONS

  def initialize(obj)
    @obj = obj
  end

  def render
    lines = []
    lines << "# #{@obj.display_name} (#{@obj.class.model_name.human})"
    lines << ''
    lines.concat(header_fields)
    lines << ''
    lines.concat(summary_section)
    lines.concat(location_section)
    lines.concat(type_sections)
    lines.concat(notes_section)
    lines.join("\n")
  end

  private

  def type_sections
    []
  end

  def summary_section
    []
  end

  def header_fields
    fields = []
    fields << "**UWP:** `#{@obj.uwp}`" if @obj.respond_to?(:uwp) && @obj.uwp.present?
    if (allegiance = @obj.allegiance)
      fields << "**Allegiance:** #{allegiance.name} (#{allegiance.code})"
    end
    fields
  end

  def location_section
    parent = @obj.orbiting
    star_system = StarSystem.find_by(id: @obj.star_system_id)
    parsec = @obj.parsec || star_system&.parsec
    subsector = parsec&.subsector
    sector = parsec&.sector

    lines = ['## Location', '']
    lines << "**Orbiting:** #{parent.display_name}" if parent
    lines << "**Star System:** #{star_system.display_name}" if star_system
    lines << "**Subsector:** #{subsector.name}" if subsector
    if sector
      hex = parsec&.hex_code
      lines << "**Sector:** #{sector.name}#{hex ? " · #{hex}" : ''}"
    end
    lines << ''
    lines
  end

  def orbital_data_section
    return [] unless @obj.respond_to?(:orbit) && @obj.orbit.present?

    star_system = StarSystem.find_by(id: @obj.star_system_id)
    parsec = @obj.parsec || star_system&.parsec

    rows = []
    rows << ['Hex', parsec.hex_code] if parsec
    if (allegiance = @obj.allegiance)
      rows << ['Allegiance', "#{allegiance.name} (#{allegiance.code})"]
    end
    rows << ['Orbit', fmt(@obj.orbit, 2)]
    rows << ['AU', "#{fmt(@obj.au, 2)} AU"] if @obj.respond_to?(:au) && @obj.au.present?
    rows << ['Period', format_period(@obj.period)] if @obj.respond_to?(:period) && @obj.period.present?
    rows << ['HZCO Deviation', fmt(@obj.effective_hzco_deviation, 2)] if @obj.respond_to?(:effective_hzco_deviation)
    rows << ['Retrograde', @obj.retrograde ? 'Yes' : 'No'] if @obj.respond_to?(:retrograde)
    rows << ['Inclination', "#{fmt(@obj.inclination, 2)}°"] if @obj.respond_to?(:inclination)
    rows << ['Eccentricity', fmt(@obj.eccentricity, 2)] if @obj.respond_to?(:eccentricity)
    if @obj.respond_to?(:tidal_lock_target) && @obj.tidal_lock_target
      rows << ['Tidally Locked', @obj.tidal_lock_target.display_name]
    end
    if @obj.respond_to?(:sidereal_day) && @obj.sidereal_day.present?
      rows << ['Sidereal Day', "#{fmt(@obj.sidereal_day, 2)} hours"]
    end
    rows << ['Twilight Zone', 'Yes'] if @obj.respond_to?(:twilight_zone) && @obj.twilight_zone
    if @obj.respond_to?(:planetoid_belt_id) && @obj.planetoid_belt_id.present?
      belt = PlanetoidBelt.find_by(id: @obj.planetoid_belt_id)
      rows << ['Belt', belt.display_name] if belt
    end
    table_section('Orbital Data', rows)
  end

  def jump_shadow_section
    distance = @obj.effective_jump_shadow_km
    return [] if distance.nil? || distance <= 0

    lines = ['## Jump Shadow', '']
    lines << "**Distance to Clear:** #{number_with_delimiter(distance.round)} km"
    source = @obj.effective_jump_shadow_source
    lines << "**Shadow Source:** #{source.display_name}" if source
    lines << ''

    times = jump_shadow_travel_times(distance)
    lines << "| #{times.keys.map { |g| "#{g}G" }.join(' | ')} |"
    lines << "| #{Array.new(times.size, '---').join(' | ')} |"
    lines << "| #{times.values.join(' | ')} |"
    lines << ''

    lines
  end

  def starport_section
    code = @obj.respond_to?(:starport_code) ? (@obj.starport_code.presence || 'X') : 'X'
    starport = StellarObjectsHelper::STARPORT_DATA[code] || StellarObjectsHelper::STARPORT_DATA['X']
    rows = [
      ['Starport', "#{code} — #{starport[:quality]}"],
      ['Fuel', starport[:fuel]],
      ['Facilities', starport[:facilities]]
    ]
    rows << ['World Trade Number', @obj.world_trade_number] if @obj.respond_to?(:world_trade_number) && @obj.world_trade_number.present?
    rows << ['Importance', format_importance(@obj.importance)] if @obj.respond_to?(:importance) && @obj.importance.present?
    rows << ['Development Score', fmt(@obj.development_score, 1)] if @obj.respond_to?(:development_score) && @obj.development_score.present?
    rows << ['Per Capita GWP', format_gwp(@obj.per_capita_gwp)] if @obj.respond_to?(:per_capita_gwp) && @obj.per_capita_gwp.present?
    rows << ['Total GWP', format_gwp(@obj.total_gwp)] if @obj.respond_to?(:total_gwp) && @obj.total_gwp.present?
    rows << ['Infrastructure', @obj.infrastructure] if @obj.respond_to?(:infrastructure) && @obj.infrastructure.present?
    rows << ['Resource Units', @obj.resource_units] if @obj.respond_to?(:resource_units) && @obj.resource_units.present?
    rows << ['Resource Factor', @obj.resource_factor] if @obj.respond_to?(:resource_factor) && @obj.resource_factor.present?
    rows << ['Labour Factor', @obj.labour_factor] if @obj.respond_to?(:labour_factor) && @obj.labour_factor.present?
    rows << ['Efficiency', @obj.efficiency] if @obj.respond_to?(:efficiency) && @obj.efficiency.present?
    rows << ['Inequality Rating', @obj.inequality_rating] if @obj.respond_to?(:inequality_rating) && @obj.inequality_rating.present?
    if @obj.respond_to?(:tariff_rate) && @obj.tariff_rate.present?
      rows << ['Tariff Regime', @obj.tariff_regime.humanize] if @obj.respond_to?(:tariff_regime) && @obj.tariff_regime.present?
      rows << ['Tariff Rate', number_to_percentage(@obj.tariff_rate, precision: 0)]
    end
    table_section('Starport', rows)
  end

  def notes_section
    return [] if @obj.notes.blank?

    ['## Notes', '', @obj.notes.strip, '']
  end

  def table_section(title, rows)
    return [] if rows.empty?

    lines = ["## #{title}", '', '| Field | Value |', '|---|---|']
    rows.each { |label, value| lines << "| #{label} | #{value} |" }
    lines << ''
    lines
  end

  def physical_data_section
    rows = [
      ['Diameter', "#{@obj.size_code} — #{number_with_delimiter(@obj.diameter&.round)} km"],
      ['Mass', "#{fmt(@obj.mass, 2)} ☉"],
      ['Gravity', "#{fmt(@obj.gravity, 2)} g"],
      ['Density', "#{fmt(@obj.density, 2)} ☉"]
    ]
    table_section('Physical Data', rows)
  end

  def environmental_data_section
    celsius = @obj.temperature ? (@obj.temperature - StellarConstants::KELVIN_TO_CELSIUS_OFFSET).round : nil
    rows = []
    rows << ['Temperature', "#{celsius}°C"] if celsius
    rows << ['Rotation', "#{fmt(@obj.rotation, 2)} hours"] if @obj.rotation.present?
    rows << ['Axial Tilt', "#{fmt(@obj.axial_tilt, 2)}°"] if @obj.axial_tilt.present?
    rows << ['Albedo', fmt(@obj.albedo, 2)] if @obj.albedo.present?
    rows << ['Greenhouse', fmt(@obj.greenhouse, 2)] if @obj.greenhouse.present?
    table_section('Environmental Data', rows)
  end

  def atmosphere_section
    atm = @obj.atmosphere
    return [] if atm.blank?

    code = atm['code']
    taint = atm['taint']
    taint_code = taint&.dig('code')

    rows = [['Atmosphere', "#{code} — #{ATMOSPHERE_DESCRIPTIONS[code]}"]]
    if taint_code.present?
      rows << ['Irritant', "#{taint_code} — #{TAINT_DESCRIPTIONS[taint_code]}"]
      rows << ['Severity', "#{taint['severity']} — #{TAINT_SEVERITY_DESCRIPTIONS[taint['severity']]}"]
      rows << ['Persistence', "#{taint['persistence']} — #{TAINT_PERSISTENCE_DESCRIPTIONS[taint['persistence']]}"]
    end
    rows << ['Composition', atm['composition']] if atm['composition'].present?
    table_section('Atmosphere', rows)
  end

  def hydrographics_section
    hyd = @obj.hydrographics
    return [] if hyd.blank?

    code = hyd['code']
    distribution = hyd['distribution']
    rows = [['Hydrographics', "#{code} — #{HYDROGRAPHICS_DESCRIPTIONS[code]}"]]
    rows << ['Liquid', hyd['liquid']] if hyd['liquid'].present?
    if distribution
      rows << ['Distribution', "#{distribution} — #{HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS[distribution]}"]
    end
    table_section('Hydrographics', rows)
  end

  def population_section
    rows = []
    pop_code = @obj.population_code
    rows << ['Population', "#{pop_code} — #{POPULATION_RANGES[pop_code.to_i]}"] if pop_code.present?
    if @obj.population_concentration_rating.present?
      cr = @obj.population_concentration_rating.to_i
      rows << ['Concentration', "#{cr} — #{CONCENTRATION_RATING_DESCRIPTIONS[cr]}"]
    end
    rows << ['Urbanisation', "#{@obj.population_urbanization_percentage}%"] if @obj.population_urbanization_percentage.present?
    rows << ['Major Cities', @obj.population_major_cities] if @obj.population_major_cities.present?
    if @obj.population_major_city_population.present?
      rows << ['Major City Population', number_with_delimiter(@obj.population_major_city_population)]
    end
    rows << ['Native Sophont', @obj.native_sophont ? 'Yes' : 'No']
    rows << ['Extinct Sophont', @obj.extinct_sophont ? 'Yes' : 'No']
    StellarObjectsHelper::CULTURE_TRAIT_DATA.each do |trait|
      val = @obj.send(trait[:getter])
      next unless val.present?

      rows << [trait[:label], "#{val} (DM #{culture_trait_dm(val)})"]
    end
    if @obj.habitability_rating.present?
      r = @obj.habitability_rating
      rows << ['Habitability Rating', "#{r} — #{HABITABILITY_RATING_DESCRIPTIONS[r]}"]
    end
    rows << ['Biomass Rating', @obj.biomass_rating] if @obj.biomass_rating.present?
    if @obj.biodiversity_rating.present?
      r = @obj.biodiversity_rating
      rows << ['Biodiversity Rating', "#{r} — #{biodiversity_description(r)}"]
    end
    if @obj.biocomplexity_rating.present?
      r = @obj.biocomplexity_rating
      rows << ['Biocomplexity Rating', "#{r} — #{BIOCOMPLEXITY_DESCRIPTIONS[r]}"]
    end
    if @obj.resource_rating.present?
      r = @obj.resource_rating
      rows << ['Resource Rating', "#{r} — #{RESOURCE_RATING_DESCRIPTIONS[r]}"]
    end
    table_section('Population', rows)
  end

  def government_section
    return [] unless @obj.government_code.present?

    gov = Government.find_by(code: @obj.government_code)
    return [] unless gov

    rows = [['Government', "#{HexDigit.hex_digit(@obj.government_code)} — #{gov.government_type}"]]
    rows << ['Description', gov.description] if gov.description.present?
    [
      [:government_judicial,    'Judicial Structure'],
      [:government_executive,   'Executive Structure'],
      [:government_legislative, 'Legislative Structure']
    ].each do |attr, label|
      val = @obj.public_send(attr)
      rows << [label, "#{val} — #{GOVERNMENT_STRUCTURE_DESCRIPTIONS[val]}"] if val.present?
    end
    if (auth = @obj.government_authority)
      rows << ['Authority', "#{auth} — #{GOVERNMENT_AUTHORITY_DESCRIPTIONS[auth]}"]
    end
    if (cent = @obj.government_centralisation)
      rows << ['Centralisation', "#{cent} — #{GOVERNMENT_CENTRALISATION_DESCRIPTIONS[cent]}"]
    end
    table_section('Government', rows)
  end

  def law_level_section
    return [] unless @obj.law_level_code.present?

    law_by_code = LawLevel.all.index_by(&:code)
    rows = [['Law Level', HexDigit.hex_digit(@obj.law_level_code)]]
    [
      ['Weapons & Armour', @obj.law_level_weapons_and_armour, :weapons],
      ['Criminal Law',     @obj.law_level_criminal_law,       :criminal_law],
      ['Economic Law',     @obj.law_level_economic_law,       :economic_law],
      ['Private Law',      @obj.law_level_private_law,        :private_law],
      ['Personal Rights',  @obj.law_level_personal_rights,    :personal_law]
    ].each do |label, sub_code, col|
      next unless sub_code

      sub = law_by_code[sub_code]
      rows << [label, "#{HexDigit.hex_digit(sub_code)} — #{sub&.public_send(col)}"]
    end
    if @obj.law_level_uniformity.present?
      rows << ['Law Uniformity', "#{@obj.law_level_uniformity} — #{LAW_UNIFORMITY_DESCRIPTIONS[@obj.law_level_uniformity]}"]
    end
    if @obj.law_level_judicial_system.present?
      rows << ['Judicial System', "#{@obj.law_level_judicial_system} — #{LAW_JUDICIAL_SYSTEM_DESCRIPTIONS[@obj.law_level_judicial_system]}"]
    end
    rows << ['Death Penalty', @obj.law_level_death_penalty ? 'Yes' : 'No']
    rows << ['Presumed Innocence', @obj.law_level_presumed_innocence ? 'Yes' : 'No']
    rows << ['Econometric Infractions Admin.', @obj.law_level_econometric_infractions_administrative ? 'Yes' : 'No']
    table_section('Law Level', rows)
  end

  def tech_level_section
    return [] unless @obj.tech_level_code.present?

    tl = TechLevel.find_by(code: @obj.tech_level_code)
    return [] unless tl

    rows = [['Tech Level', "#{HexDigit.hex_digit(@obj.tech_level_code)} — #{tl.descriptor}"]]
    rows << ['Era', tl.short_description] if tl.short_description.present?

    tl_data = @obj.data&.dig('tech_level')
    if tl_data.present?
      tl_records = TechLevel.where(code: tl_data.values.grep(Integer).uniq).index_by(&:code)
      %i[electronics energy land sea air space personal_military heavy_military manufacturing medical environmental].each do |cap|
        c = tl_data[cap.to_s]
        next unless c
        val = tl_records[c]&.public_send(cap)
        rows << [cap.to_s.humanize, "#{HexDigit.hex_digit(c)} — #{val}"] if val.present?
      end
    else
      %i[electronics energy land sea air space personal_military heavy_military manufacturing medical environmental].each do |cap|
        val = tl.public_send(cap)
        rows << [cap.to_s.humanize, val] if val.present?
      end
    end
    rows << ['Environmental', tl.environmental] if tl.environmental.present?
    table_section('Tech Level', rows)
  end

  def fmt(value, precision)
    return '' if value.nil?

    number_with_precision(value, precision: precision, strip_insignificant_zeros: true)
  end

  def format_period(period)
    return '' if period.nil?

    if period > 730
      "#{number_with_precision(period / 365.25, precision: 1, strip_insignificant_zeros: true)} y"
    else
      "#{number_with_precision(period, precision: 1, strip_insignificant_zeros: true)} d"
    end
  end

  def format_importance(value)
    return nil if value.nil?

    value >= 0 ? "+#{value}" : value.to_s
  end

  def format_gwp(value)
    return nil if value.nil?

    number_to_human(value, units: { thousand: 'K', million: 'M', billion: 'B', trillion: 'Tr' }, precision: 2)
  end

  def atmosphere_survival_requirement(code, tainted: false)
    return 'None' if code.nil?

    base = ATMOSPHERE_SURVIVAL_REQUIREMENTS[code] || 'None'
    return base unless tainted

    case base
    when 'None' then 'Filter Mask'
    when 'Respirator' then 'Respirator + Filter'
    else base
    end
  end

  def culture_trait_dm(value)
    return nil if value.nil?

    case value.to_i
    when 1..2   then '±2'
    when 3..5   then '±1'
    when 6..8   then '±0'
    when 9..11  then '±1'
    when 12..14 then '±2'
    when 15..17 then '±3'
    else             '±4'
    end
  end

  def biodiversity_description(rating)
    return nil if rating.nil?

    if rating >= 10
      'Complexity equivalent to pre-human Terra'
    elsif rating < 3
      'Very uniform biosphere'
    else
      'Moderate species diversity'
    end
  end
end
