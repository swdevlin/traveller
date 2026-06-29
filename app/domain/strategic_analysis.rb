# frozen_string_literal: true

class StrategicAnalysis
  NAVAL_CODES    = %w[N D].freeze
  SCOUT_CODES    = %w[S W].freeze
  SUPPLIER_CODES = %w[Ag Ga Wa As].freeze
  MARKET_CODES   = %w[Ri In].freeze

  ROLE_STYLES = {
    market:    { css_class: 'strat-role-market',    label: 'MARKET',    description: 'Trade centre — strong economic activity' },
    supplier:  { css_class: 'strat-role-supplier',  label: 'SUPPLIER',  description: 'Commodity source — agricultural or resource-rich' },
    extractor: { css_class: 'strat-role-extractor', label: 'EXTRACTOR', description: 'Resource extraction — high raw value, low development' },
    deficit:   { css_class: 'strat-role-deficit',   label: 'DEFICIT',   description: 'Deficit system — negative resource units, requires external subsidy' }
  }.freeze

  attr_reader :star_system

  def initialize(star_system)
    @star_system = star_system
  end

  # --- Importance ---

  def importance
    return nil unless main_world&.respond_to?(:importance)

    main_world.importance&.to_i
  end

  def importance_tier
    ix = importance
    return 1 if ix.nil?

    case ix
    when ..-1  then 0
    when 0..1  then 1
    when 2     then 2
    when 3     then 3
    when 4     then 4
    else            5
    end
  end

  # --- Economy ---

  def resource_units_score
    return 0 unless main_world&.respond_to?(:resource_units)

    main_world.resource_units&.to_i || 0
  end

  def resource_units_tier
    case resource_units_score
    when ...0   then 0
    when 1..10   then 1
    when 11..30   then 2
    when 31..90  then 3
    when 91..200 then 4
    else             5
    end
  end

  # --- Resources ---

  def resource_score
    main_world&.resource_factor.to_f
  end

  def resource_tier
    rf = resource_score
    case rf
    when ..0   then 1
    when 1..2  then 2
    when 3..9  then 3
    when 10..15 then 4
    else            5
    end
  end

  # --- Trade ---

  def trade_friction_score
    score = 0
    tz_code = star_system.travel_zone&.code&.upcase

    score += 4 if tz_code == 'R'
    score += 2 if tz_code == 'A'

    if main_world&.respond_to?(:law_level_code)
      ll = main_world.law_level_code.to_i
      score += 1 if ll >= 7
      score += 1 if ll >= 9
    end

    if main_world&.respond_to?(:government_code)
      gc = main_world.government_code.to_i
      score += 1 if gc == 0 || (7..13).cover?(gc)
    end

    if main_world&.respond_to?(:population_xenophilia)
      xeno = main_world.population_xenophilia.to_i
      score += 1 if xeno <= 2
      score += 1 if xeno <= 0
    end

    if main_world&.respond_to?(:population_militancy)
      score += 1 if main_world.population_militancy.to_i >= 7
    end

    if main_world&.respond_to?(:population_expansionism)
      score += 1 if main_world.population_expansionism.to_i >= 8
    end

    if main_world&.respond_to?(:population_uniqueness)
      score += 1 if main_world.population_uniqueness.to_i >= 8
    end

    if main_world&.respond_to?(:population_symbology)
      score += 1 if main_world.population_symbology.to_i >= 8
    end

    [[score, 0].max, 9].min
  end

  def trade_ease_score
    10 - trade_friction_score
  end

  def trade_ease_tier
    score = trade_ease_score
    case score
    when ...4  then 1
    when 4...6 then 2
    when 6...8 then 3
    when 8...10 then 4
    else             5
    end
  end

  # --- Route Role ---

  def route_role
    tz_code = star_system.travel_zone&.code&.upcase

    # if importance_tier >= 4 && (naval_base? || importance_tier == 5)
    #   return :anchor
    # end

    # if importance_tier >= 3 && trade_ease_tier >= 3 && scout_base?
    #   return :relay
    # end

    tc = trade_code_set
    # if resource_units_tier >= 4 || (resource_units_tier >= 3 && (tc.include?('Ri') || tc.include?('In')))
    if tc.include?('Ri') || tc.include?('In')
      return :market
    end

    if resource_tier >= 4 || (SUPPLIER_CODES.any? { |c| tc.include?(c) } && resource_units_tier >= 2)
      return :supplier
    end

    return :extractor if resource_tier >= 3 && resource_units_tier <= 2

    # return :outpost if tz_code == 'A' || (importance_tier <= 2 && base_codes.any?)

    return :deficit if resource_units_score.negative?

    nil
  end

  def route_role_style
    ROLE_STYLES[route_role]
  end

  def route_role_label
    route_role_style&.fetch(:label)
  end

  HEAT_COLOURS = {
    -3 => '#f87171',
    -2 => '#fca5a5',
    -1 => '#fee2e2',
     0 => '#e5e7eb',
     1 => '#dcfce7',
     2 => '#bbf7d0',
     3 => '#86efac',
     4 => '#4ade80',
     5 => '#22c55e'
  }.freeze

  def heat_colour
    ix = importance
    return nil if ix.nil?

    clamped = ix.clamp(-3, 5)
    HEAT_COLOURS[clamped]
  end

  # --- Culture Modifiers ---

  def route_modifiers
    return [] unless main_world&.respond_to?(:population_xenophilia)

    mods = []

    xeno = main_world.population_xenophilia.to_i
    mods << { text: 'Xeno-', css_class: 'strat-mod-negative' } if xeno <= 2

    mods << { text: 'Mil+',  css_class: 'strat-mod-positive' } if pop_int(:population_militancy)  >= 7
    mods << { text: 'Exp+',  css_class: 'strat-mod-positive' } if pop_int(:population_expansionism) >= 7
    mods << { text: 'Prog+', css_class: 'strat-mod-positive' } if pop_int(:population_progressiveness) >= 7
    mods << { text: 'Div+',  css_class: 'strat-mod-positive' } if pop_int(:population_diversity)   >= 7
    mods << { text: 'Uniq+', css_class: 'strat-mod-neutral'  } if pop_int(:population_uniqueness)  >= 8

    mods
  end

  private

  def main_world
    @main_world ||= star_system.main_world
  end

  def base_codes
    @base_codes ||= begin
      facs = star_system.facilities
      already_loaded = !facs.respond_to?(:loaded?) || facs.loaded?
      already_loaded ? facs.map(&:code) : facs.pluck(:code)
    end
  end

  def naval_base?
    base_codes.any? { |c| NAVAL_CODES.include?(c.upcase) }
  end

  def scout_base?
    base_codes.any? { |c| SCOUT_CODES.include?(c.upcase) }
  end

  def trade_code_set
    @trade_code_set ||= begin
      tcs = star_system.trade_codes
      already_loaded = !tcs.respond_to?(:loaded?) || tcs.loaded?
      (already_loaded ? tcs.map(&:code) : tcs.pluck(:code)).to_set
    end
  end

  def pop_int(method_name)
    return 0 unless main_world&.respond_to?(method_name)

    main_world.public_send(method_name).to_i
  end
end
