# frozen_string_literal: true

# How stellar objects are drawn on the schematic maps: which image in
# public/stellar_objects/ represents them, and the fallback fill colour. Mirrors the
# rules in the Elm starmap (StarSystemMap.elm), so the Rails maps match the Elm ones.
module StellarObjectAppearance
  STANDARD_STAR_TYPES = %w[O B A F G K M BD NS D PS L T Y].freeze

  ICE_THRESHOLD_K = 263.15 # -10 °C
  HOT_ROCKBALL_THRESHOLD_K = 473.15 # 200 °C
  MOLTEN_THRESHOLD_K = 673.15 # 400 °C
  SPARSE_ATMOSPHERE_DENSITIES = %w[Trace Thin Very\ Thin].freeze

  GAS_GIANT_COLOUR = '#8b5cf6'
  PLANETOID_BELT_COLOUR = '#64748b'

  # Star fill colours, for stars drawn without an image.
  STAR_FILL_COLOURS = {
    'Blue' => '#3366BB',
    'Blue White' => '#5588CC',
    'White' => '#8899AA',
    'Yellow White' => '#BBAA44',
    'Yellow' => '#CC8800',
    'Light Orange' => '#CC6622',
    'Orange Red' => '#CC3311',
    'Red' => '#BB1111',
    'Brown' => '#886644',
    'Deep Dim Red' => '#882255'
  }.freeze
  UNKNOWN_STAR_FILL_COLOUR = '#778899'

  private

  def star_fill_colour(star)
    STAR_FILL_COLOURS.fetch(star.colour, UNKNOWN_STAR_FILL_COLOUR)
  end

  def star_image(star)
    type = star.stellar_type.to_s.upcase
    :"#{type.downcase}_star" if STANDARD_STAR_TYPES.include?(type)
  end

  def gas_giant_image(body)
    case body.code
    when 'GS' then :gg_small
    when 'GM' then :gg_medium
    when 'GL' then :gg_large
    end
  end

  def terrestrial_image(body)
    atmo_code = body.atmosphere&.code || 0
    hydro_code = body.hydrographics&.code || 0
    return :unusual if atmo_code == 10
    return :corrosive if atmo_code == 11
    return :insidious if atmo_code == 12
    return :dense if atmo_code == 13
    return :low if atmo_code == 14
    return :unusual if atmo_code == 15
    return :helium if atmo_code == 16
    return :hydrogen if atmo_code == 17
    return :biological if body.atmosphere&.taint_code.to_s.upcase == 'B'
    if hydro_code == 0
      return :hot_rockball if body.temperature.present? && body.temperature.to_f > HOT_ROCKBALL_THRESHOLD_K
      density = body.atmosphere&.density.to_s
      return :trace if SPARSE_ATMOSPHERE_DENSITIES.any? { |d| density.start_with?(d) }
      return :desert
    end
    return :molten if hydro_code > 0 && body.temperature.present? && body.temperature.to_f >= MOLTEN_THRESHOLD_K
    return :ice if hydro_code > 0 && body.temperature.present? && body.temperature.to_f < ICE_THRESHOLD_K
    if atmo_code <= 9
      return :waterworld if hydro_code == 10
      return :"tp_#{hydro_code * 10}" if (1..9).cover?(hydro_code)
    end

    nil
  end

  def terrestrial_colour(body)
    atmo_code = body.atmosphere&.code || 0
    hydro_code = body.hydrographics&.code || 0

    # Exotic/hostile atmospheres
    return '#16a34a' if atmo_code == 10 # exotic — green
    return '#f59e0b' if atmo_code == 11 # corrosive — amber
    return '#ef4444' if atmo_code == 12 # insidious — red

    # No atmosphere: airless rock
    return '#78716c' if atmo_code == 0

    # Has atmosphere, increasing water coverage
    return '#d97706' if hydro_code == 0
    return '#b45309' if hydro_code <= 2
    return '#0e7490' if hydro_code <= 4
    return '#0369a1' if hydro_code <= 6
    return '#1d4ed8' if hydro_code <= 8
    '#1e40af' # water world
  end
end
