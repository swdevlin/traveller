# frozen_string_literal: true

# Determines how many Low/Basic/Middle/High passengers are seeking passage from
# +from_system+ to +to_system+, following the Passenger Traffic procedure (Mongoose
# Traveller 2e, p.239). Every roll is logged on +roller+ for a full audit trail.
class PassengerTrafficCalculator
  include HexDistance

  PASSENGER_TYPES = %i[low basic middle high].freeze
  POPULATION_MAX  = 12

  attr_reader :roller, :results, :shared_modifiers, :parsec_distance

  # @param system [StarSystem]
  # @param dms [Hash<Symbol, Integer>] resolved DM values, see PassengerTrafficDms.for
  # @return [Array<Hash>] population/starport/zone DM breakdown for a single world, with
  #   no role suffix on the labels — suitable for display next to a system selector.
  def self.world_modifiers(system, dms)
    modifiers = []

    pop_dm = population_dm(dms, population_digit(system))
    modifiers << { label: "Population #{population_label(population_digit(system))}", value: pop_dm } if pop_dm != 0

    port_dm = starport_dm(dms, starport_code(system))
    modifiers << { label: "Starport #{starport_code(system)}", value: port_dm } if port_dm != 0

    zone_value = zone_dm(dms, zone_code(system))
    modifiers << { label: "#{zone_label(zone_code(system))} Zone", value: zone_value } if zone_value != 0

    modifiers
  end

  class << self
    private

    def population_digit(system)
      char = system.main_world_uwp&.[](4)
      return 0 if char.nil?

      HexDigit::HEX_DIGITS.index(char) || 0
    end

    def population_index(digit)
      return 0 if digit <= 1

      [digit, POPULATION_MAX].min - 1
    end

    def population_label(digit)
      return '≤1' if digit <= 1

      [digit, POPULATION_MAX].min.to_s
    end

    def population_dm(dms, digit)
      dms[:population][population_index(digit)]
    end

    def starport_code(system)
      system.main_world_uwp&.[](0)
    end

    def starport_dm(dms, code)
      case code
      when 'A' then dms[:starport_a]
      when 'B' then dms[:starport_b]
      when 'C' then dms[:starport_c]
      when 'D' then dms[:starport_d]
      when 'E' then dms[:starport_e]
      when 'X' then dms[:starport_x]
      else 0
      end
    end

    def zone_code(system)
      system.travel_zone&.code
    end

    def zone_label(code)
      { 'A' => 'Amber', 'R' => 'Red' }.fetch(code, code.to_s)
    end

    def zone_dm(dms, code)
      case code
      when 'A' then dms[:zone_amber]
      when 'R' then dms[:zone_red]
      else 0
      end
    end
  end

  def initialize(from_system:, to_system:, campaign:, broker_effect: 0, chief_steward_skill: 0,
                 referee_modifier: 0, seed: nil)
    @from_system         = from_system
    @to_system           = to_system
    @dms                 = PassengerTrafficDms.for(campaign)
    @broker_effect       = broker_effect.to_i
    @chief_steward_skill = chief_steward_skill.to_i
    @referee_modifier    = referee_modifier.to_i
    @roller              = DiceRoller.new(seed: seed)
    @results             = {}
  end

  def calculate
    @parsec_distance  = hex_distance([@from_system.parsec.x, @from_system.parsec.y],
                                      [@to_system.parsec.x, @to_system.parsec.y])
    @shared_modifiers = build_shared_modifiers

    PASSENGER_TYPES.each do |type|
      @results[type] = roll_for(type)
    end

    self
  end

  private

  def build_shared_modifiers
    modifiers = []
    modifiers.concat(world_modifiers(@from_system, 'origin'))
    modifiers.concat(world_modifiers(@to_system, 'destination'))

    if @parsec_distance > 1
      value = @dms[:per_parsec] * (@parsec_distance - 1)
      modifiers << { label: "Distance #{@parsec_distance} parsecs", value: value }
    end

    modifiers << { label: 'Skill Effect', value: @broker_effect } if @broker_effect != 0
    modifiers << { label: 'Steward', value: @chief_steward_skill } if @chief_steward_skill != 0
    modifiers << { label: 'Other DM', value: @referee_modifier } if @referee_modifier != 0
    modifiers
  end

  def world_modifiers(system, role)
    self.class.world_modifiers(system, @dms).map { |m| m.merge(label: "#{m[:label]} (#{role})") }
  end

  def roll_for(type)
    type_dm = case type
    when :high then @dms[:high_passenger]
    when :low  then @dms[:low_passenger]
    else 0
    end

    modifiers = shared_modifiers.dup
    modifiers << { label: "Rolling for #{type.to_s.capitalize}", value: type_dm } if type_dm != 0

    total_dm = modifiers.sum { |m| m[:value] }
    qualifying_total = @roller.roll(n: 2, d: 6, dm: total_dm, note: "#{type.to_s.capitalize} passenger qualifying roll")
    qualifying_roll = roll_detail(qualifying_total)

    dice_code = PassengerTrafficTable.dice_for(qualifying_total)

    if dice_code.nil?
      { passengers: 0, modifiers: modifiers, qualifying_roll: qualifying_roll, count_roll: nil }
    else
      n, d = dice_code
      count_total = @roller.roll(n: n, d: d, dm: 0, note: "#{type.to_s.capitalize} passenger count")
      count_roll = roll_detail(count_total)
      { passengers: count_total, modifiers: modifiers, qualifying_roll: qualifying_roll, count_roll: count_roll }
    end
  end

  def roll_detail(total)
    @roller.log.last.merge(total: total)
  end
end
