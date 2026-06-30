class PlanetoidMarkdownPresenter < MarkdownPresenterBase
  private

  def jump_shadow_section
    distance = @obj.effective_jump_shadow_km
    return [] if distance.nil? || distance <= 0

    lines = ['## Jump Shadow', '']
    lines << "**Distance to Clear:** #{number_with_delimiter(distance.round)} km"
    source = @obj.effective_jump_shadow_source
    lines << "**Shadow Source:** #{source.display_name}" if source
    lines << ''
    lines
  end

  def summary_section
    planetary_profile_summary
  end

  def type_sections
    orbital_data_section +
      jump_shadow_section +
      starport_section +
      physical_data_section +
      environmental_data_section +
      atmosphere_section +
      hydrographics_section +
      population_section +
      government_section +
      law_level_section +
      tech_level_section
  end

  def planetary_profile_summary
    atmosphere = @obj.atmosphere
    atmosphere_code = atmosphere&.code
    atmosphere_tainted = atmosphere&.tainted?
    population = @obj.population
    population_code = population&.dig('code')
    government = @obj.government ? Government.find_by(code: @obj.government.code) : nil
    law_level = @obj.law_level_code.present? ? LawLevel.find_by(code: @obj.law_level_code) : nil
    tl = @obj.tech_level_code.present? ? TechLevel.find_by(code: @obj.tech_level_code) : nil
    sophont_status = if @obj.extinct_sophont then 'Extinct' elsif @obj.native_sophont then 'Extant' else 'None' end

    rows = []
    rows << ['UWP', @obj.uwp] if @obj.uwp.present?
    if @obj.starport_code.present?
      starport = StellarObjectsHelper::STARPORT_DATA[@obj.starport_code]
      rows << ['Starport', "#{@obj.starport_code} — #{starport[:quality]}; #{starport[:fuel]}; #{starport[:facilities]}"] if starport
    end
    rows << ['Gravity', "#{fmt(@obj.gravity, 2)} g"] if @obj.gravity.present?
    if @obj.temperature.present?
      celsius = (@obj.temperature - StellarConstants::KELVIN_TO_CELSIUS_OFFSET).round
      rows << ['Temperature', "#{celsius}°C"]
    end
    rows << ['Survival Req.', atmosphere_survival_requirement(atmosphere_code, tainted: atmosphere_tainted)]
    rows << ['Population', "#{HexDigit.hex_digit(population_code.to_i)} — #{POPULATION_RANGES[population_code.to_i]}"] if population_code.present?
    rows << ['Government', "#{HexDigit.hex_digit(government.code)} — #{government.government_type}"] if government
    rows << ['Law Level', "#{HexDigit.hex_digit(law_level.code)} — #{law_level.weapons}"] if law_level
    if tl
      tl_value = "#{HexDigit.hex_digit(tl.code)} — #{tl.descriptor}"
      tl_value += "; #{tl.short_description}" if population_code.present? && population_code.to_i > 0 && tl.short_description.present?
      rows << ['Tech Level', tl_value]
    end
    rows << ['Native Sophont', sophont_status]

    lines = table_section('Planetary Profile', rows)

    distance = @obj.effective_jump_shadow_km
    if distance&.positive?
      times = jump_shadow_travel_times(distance)
      lines << '## Jump Shadow Times'
      lines << ''
      lines << "| #{times.keys.map { |g| "#{g}G" }.join(' | ')} |"
      lines << "| #{Array.new(times.size, '---').join(' | ')} |"
      lines << "| #{times.values.join(' | ')} |"
      lines << ''
    end

    lines
  end
end
