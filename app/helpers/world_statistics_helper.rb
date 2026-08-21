module WorldStatisticsHelper
  POPULATION_SCALES = [
    [1_000_000_000_000, 'trillion'],
    [1_000_000_000, 'billion'],
    [1_000_000, 'million'],
    [1_000, 'thousand']
  ].freeze

  def abbreviated_population(value)
    return nil if value.blank?

    value = value.to_i
    scale, name = POPULATION_SCALES.find { |threshold, _| value >= threshold }

    text =
      if scale
        scaled = value.to_f / scale
        magnitude = Math.log10(scaled).floor
        decimals = [3 - 1 - magnitude, 0].max
        "#{number_with_precision(scaled, precision: decimals, strip_insignificant_zeros: true)} #{name}"
      else
        number_with_delimiter(value)
      end

    tag.span(text, title: number_with_delimiter(value))
  end

  def population_summary_fragment(stats, highest_population_world)
    total_text =
      if stats.worlds_with_known_census_count.positive?
        safe_join([abbreviated_population(stats.total_population.to_i), ' population'])
      else
        'incomplete census data'
      end

    highest_world_fragment = highest_population_world && content_tag(:span, data: { controller: 'stop-propagation', action: 'click->stop-propagation#stop' }) {
      safe_join([
        ' (',
        link_to(highest_population_world.name.presence || 'unnamed system', stellar_object_path(highest_population_world), class: 'no-underline hover:underline'),
        ' ',
        (highest_population_world.census_population.present? ? abbreviated_population(highest_population_world.census_population) : population_range(highest_population_world.population_code)),
        ')'
      ])
    }

    safe_join([total_text, highest_world_fragment].compact)
  end

  def tech_level_bars(stats, tech_levels_by_code)
    stats.tech_level_histogram.reverse_each.map do |code, count|
      record = tech_levels_by_code[code]
      { label: tag.span(HexDigit.hex_digit(code), class: 'identifier-sm'), href: (tech_level_path(record) if record), count: count }
    end
  end

  def government_bars(stats, governments_by_code)
    stats.government_histogram.map do |code, count|
      record = governments_by_code[code]
      label = tag.span(HexDigit.hex_digit(code), class: 'identifier-sm', title: record&.government_type)
      { label: label, href: (government_path(record) if record), count: count }
    end
  end

  def law_level_bars(stats, law_levels_by_code)
    stats.law_level_histogram.map do |code, count|
      record = law_levels_by_code[code]
      { label: tag.span(HexDigit.hex_digit(code), class: 'identifier-sm'), href: (law_level_path(record) if record), count: count }
    end
  end

  STARPORT_ORDER = %w[A B C D E X].freeze

  def starport_bars(stats)
    stats.starport_histogram.sort_by { |code, _| STARPORT_ORDER.index(code) || STARPORT_ORDER.size }.map do |code, count|
      { label: tag.span(code, class: 'identifier-sm'), count: count }
    end
  end

  def travel_zone_bars(stats, travel_zones_by_id)
    stats.travel_zone_histogram.filter_map do |id, count|
      record = travel_zones_by_id[id]
      next unless record

      [record.name, { label: tag.span(record.code, class: 'identifier-sm', title: record.name), href: travel_zone_path(record), count: count }]
    end.sort_by(&:first).map(&:last)
  end

  def allegiance_bars(stats, allegiances_by_id)
    stats.allegiance_histogram.filter_map do |id, count|
      record = allegiances_by_id[id]
      next unless record

      label = tag.span(record.code, class: 'identifier-sm', title: record.name)
      { label: label, href: allegiance_path(record), count: count }
    end.sort_by { |bar| -bar[:count] }
  end

  def facility_bars(stats, facilities_by_id)
    stats.facility_histogram.filter_map do |id, count|
      record = facilities_by_id[id]
      next unless record

      [record.code, { label: tag.span(record.code, class: 'identifier-sm', title: record.name), href: facility_path(record), count: count }]
    end.sort_by(&:first).map(&:last)
  end

  def trade_code_bars(stats, trade_codes_by_id)
    stats.trade_code_histogram.filter_map do |id, count|
      record = trade_codes_by_id[id]
      next unless record

      [record.code, { label: tag.span(record.code, class: 'identifier-sm', title: record.definition), href: trade_code_path(record), count: count }]
    end.sort_by(&:first).map(&:last)
  end
end
