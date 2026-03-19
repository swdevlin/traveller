class StarSystemMarkdownPresenter
  include ActionView::Helpers::NumberHelper

  def initialize(star_system)
    @sys = star_system
  end

  def render
    lines = []
    lines << "# #{@sys.display_name} (Star System)"
    lines << ''
    lines.concat(header_fields)
    lines << ''
    lines.concat(location_section)
    lines.concat(system_data_section)
    lines.concat(stars_section)
    lines.concat(notes_section)
    lines.join("\n")
  end

  private

  def header_fields
    fields = []
    fields << "**UWP:** `#{@sys.main_world_uwp}`" if @sys.main_world_uwp.present?
    if (allegiance = @sys.allegiance)
      fields << "**Allegiance:** #{allegiance.name} (#{allegiance.code})"
    end
    fields << "**Trade Codes:** #{@sys.trade_codes_string}" if @sys.trade_codes_string.present?
    fields << "**Facilities:** #{@sys.facilities_string}" if @sys.facilities_string.present?
    fields
  end

  def location_section
    parsec = @sys.parsec
    subsector = parsec&.subsector
    sector = parsec&.sector

    lines = ['## Location', '']
    lines << "**Subsector:** #{subsector.name}" if subsector
    if sector
      hex = parsec&.hex_code
      lines << "**Sector:** #{sector.name}#{hex ? " · #{hex}" : ''}"
    end
    lines << ''
    lines
  end

  def system_data_section
    rows = [
      ['PBG', @sys.pbg],
      ['Age', "#{@sys.age} Gyr"],
      ['Gas Giants', @sys.gas_giant_count],
      ['Planetoid Belts', @sys.belt_count],
      ['Terrestrial Planets', @sys.terrestrial_count]
    ]
    rows << ['Survey Index', @sys.survey_index] if @sys.survey_index.present?
    table_section('System Data', rows)
  end

  def stars_section
    stars = @sys.ordered_stars
    return [] if stars.empty?

    lines = ['## Stars', '']
    stars.each do |star|
      lines << "### #{star.display_name}"
      lines << ''
      rows = [
        ['Classification', star.spectral_classification],
        ['Temperature', "#{number_with_delimiter(star.temperature)} K"],
        ['Mass', "#{fmt(star.mass, 2)} ☉"],
        ['Luminosity', "#{fmt(star.luminosity, 2)} ☉"],
        ['HZCO', fmt(star.hzco, 2)]
      ]
      rows << ['Orbit', fmt(star.orbit, 2)] if star.orbit.present?
      rows.each { |label, value| lines << "| #{label} | #{value} |" }
      lines << ''
    end
    lines
  end

  def notes_section
    return [] if @sys.notes.blank?

    ['## Notes', '', @sys.notes.strip, '']
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
end
