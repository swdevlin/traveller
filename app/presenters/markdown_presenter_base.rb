class MarkdownPresenterBase
  include ActionView::Helpers::NumberHelper

  ATMOSPHERE_DESCRIPTIONS = StellarObjectsHelper::ATMOSPHERE_DESCRIPTIONS
  HYDROGRAPHICS_DESCRIPTIONS = StellarObjectsHelper::HYDROGRAPHICS_DESCRIPTIONS
  HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS = StellarObjectsHelper::HYDROGRAPHICS_DISTRIBUTION_DESCRIPTIONS
  TAINT_DESCRIPTIONS = StellarObjectsHelper::TAINT_DESCRIPTIONS
  TAINT_SEVERITY_DESCRIPTIONS = StellarObjectsHelper::TAINT_SEVERITY_DESCRIPTIONS
  TAINT_PERSISTENCE_DESCRIPTIONS = StellarObjectsHelper::TAINT_PERSISTENCE_DESCRIPTIONS
  RESOURCE_RATING_DESCRIPTIONS = StellarObjectsHelper::RESOURCE_RATING_DESCRIPTIONS
  BIOCOMPLEXITY_DESCRIPTIONS = StellarObjectsHelper::BIOCOMPLEXITY_DESCRIPTIONS
  POPULATION_RANGES = StellarObjectsHelper::POPULATION_RANGES

  def initialize(obj)
    @obj = obj
  end

  def render
    lines = []
    lines << "# #{@obj.display_name} (#{@obj.class.model_name.human})"
    lines << ''
    lines.concat(header_fields)
    lines << ''
    lines.concat(location_section)
    lines.concat(type_sections)
    lines.concat(notes_section)
    lines.join("\n")
  end

  private

  def type_sections
    []
  end

  def header_fields
    fields = []
    fields << "**UWP:** `#{@obj.uwp}`" if @obj.respond_to?(:uwp) && @obj.uwp.present?
    if @obj.respond_to?(:starport_code) && @obj.starport_code.present?
      fields << "**Starport:** #{@obj.starport_code}"
    end
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

    rows = []
    rows << ['Orbit', fmt(@obj.orbit, 2)]
    rows << ['AU', "#{fmt(@obj.au, 2)} AU"] if @obj.respond_to?(:au) && @obj.au.present?
    rows << ['Period', format_period(@obj.period)] if @obj.respond_to?(:period) && @obj.period.present?
    rows << ['HZCO Deviation', fmt(@obj.effective_hzco_deviation, 2)] if @obj.respond_to?(:effective_hzco_deviation)
    rows << ['Retrograde', @obj.retrograde ? 'Yes' : 'No'] if @obj.respond_to?(:retrograde)
    rows << ['Inclination', "#{fmt(@obj.inclination, 2)}°"] if @obj.respond_to?(:inclination)
    rows << ['Eccentricity', fmt(@obj.eccentricity, 2)] if @obj.respond_to?(:eccentricity)
    table_section('Orbital Data', rows)
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

  def biological_data_section
    rows = []
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
    table_section('Biological Data', rows)
  end

  def social_data_section
    rows = []
    pop_code = @obj.population_code
    rows << ['Population', "#{pop_code} — #{POPULATION_RANGES[pop_code.to_i]}"] if pop_code.present?
    rows << ['Native Sophont', @obj.native_sophont ? 'Yes' : 'No']
    rows << ['Extinct Sophont', @obj.extinct_sophont ? 'Yes' : 'No']
    if @obj.government_code.present?
      gov = Government.find_by(code: @obj.government_code)
      rows << ['Government', "#{@obj.government_code} — #{gov&.government_type}"] if gov
    end
    if @obj.law_level_code.present?
      law = LawLevel.find_by(code: @obj.law_level_code)
      rows << ['Law Level', "#{@obj.law_level_code} — #{law&.weapons}"] if law
    end
    rows << ['Tech Level', @obj.tech_level_code] if @obj.tech_level_code.present?
    table_section('Social Data', rows)
  end
end
