class StarSystemMarkdownPresenter < MarkdownPresenterBase
  def initialize(star_system, campaign)
    super(star_system)
    @campaign = campaign
  end

  def render
    lines = []
    lines << "# #{@obj.display_name} (Star System)"
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
    fields << "**UWP:** `#{@obj.main_world_uwp}`" if @obj.main_world_uwp.present?
    if (allegiance = @obj.allegiance)
      fields << "**Allegiance:** #{allegiance.name} (#{allegiance.code})"
    end
    if (tz = @obj.travel_zone)
      fields << "**Travel Zone:** #{tz.name} (#{tz.code})"
    end
    fields << "**Trade Codes:** #{@obj.trade_codes_string}" if @obj.trade_codes_string.present?
    if (ref = @obj.effective_reference_url(@campaign)).present?
      fields << "**Library Data:** #{ref}"
    end
    fields << "**Facilities:** #{@obj.facilities_string}" if @obj.facilities_string.present?
    fields
  end

  def location_section
    parsec = @obj.parsec

    lines = ['## Location', '']
    lines.concat(subsector_sector_lines(parsec))
    lines << ''
    lines
  end

  def system_data_section
    rows = [
      ['Age', "#{@obj.age} Gyr"],
      ['Gas Giants', @obj.gas_giant_count],
      ['Planetoid Belts', @obj.belt_count],
      ['Terrestrial Planets', @obj.terrestrial_count]
    ]
    rows << ['Survey Index', @obj.survey_index] if @obj.survey_index.present?
    table_section('System Data', rows)
  end

  def stars_section
    stars = @obj.ordered_stars
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
end
