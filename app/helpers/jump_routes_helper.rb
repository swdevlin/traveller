# frozen_string_literal: true

module JumpRoutesHelper
  REFUELING_LABELS = {
    'any'        => 'Any',
    'commercial' => 'Commercial (D+ starport)',
    'refined'    => 'Refined only (A/B starport)',
    'wilderness' => 'Wilderness (gas giant)'
  }.freeze

  def refueling_label(code)
    REFUELING_LABELS.fetch(code, code.capitalize)
  end

  def star_system_search_label(system)
    return '' unless system

    system.name.presence || "#{system.parsec.sector.name} #{system.parsec.hex_code}"
  end

  def jump_length_bars(length_histogram)
    length_histogram.map do |length, count|
      { label: "#{length} parsec#{'s' unless length == 1}", count: count }
    end
  end

  def link_count_bars(link_count_histogram)
    link_count_histogram.map do |link_count, systems|
      { label: "#{link_count} link#{'s' unless link_count == 1}", count: systems }
    end
  end

  def population_bars(stats)
    stats.population_histogram.map do |code, count|
      label = tag.span(HexDigit.hex_digit(code), class: 'identifier-sm', title: population_range(code))
      { label: label, count: count }
    end
  end
end
