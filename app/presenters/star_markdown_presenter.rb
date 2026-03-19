class StarMarkdownPresenter < MarkdownPresenterBase
  private

  def type_sections
    stellar_properties_section +
      (@obj.orbiting ? orbital_data_section : []) +
      star_system_data_section
  end

  def stellar_properties_section
    rows = [
      ['Spectral Type', @obj.stellar_type],
      ['Subtype', @obj.stellar_subtype],
      ['Luminosity Class', @obj.stellar_class],
      ['Colour', @obj.colour],
      ['Temperature', "#{number_with_delimiter(@obj.temperature)} K"],
      ['Age', "#{fmt(@obj.age, 2)} Gyr"],
      ['Mass', "#{fmt(@obj.mass, 2)} ☉"],
      ['Diameter', "#{fmt(@obj.diameter, 2)} ☉"],
      ['Luminosity', "#{fmt(@obj.luminosity, 2)} ☉"],
      ['Protostar', @obj.is_protostar ? 'Yes' : 'No']
    ]
    table_section('Stellar Properties', rows)
  end

  def star_system_data_section
    rows = [
      ['Minimum Orbit', fmt(@obj.minimum_allowable_orbit, 2)],
      ['HZCO', fmt(@obj.hzco, 2)],
      ['Jump Shadow', "#{number_with_delimiter(@obj.jump_shadow&.round)} km"]
    ]
    table_section('System Data', rows)
  end

  def location_section
    star_system = @obj.star_system
    parsec = star_system&.parsec
    subsector = parsec&.subsector
    sector = parsec&.sector

    lines = ['## Location', '']
    lines << "**Star System:** #{star_system.display_name}" if star_system
    lines << "**Subsector:** #{subsector.name}" if subsector
    if sector
      hex = parsec&.hex_code
      lines << "**Sector:** #{sector.name}#{hex ? " · #{hex}" : ''}"
    end
    lines << ''
    lines
  end
end
