# frozen_string_literal: true

# Determines whether mail is available for shipment from +from_system+ to
# +to_system+, following the Mail procedure (Mongoose Traveller 2e, p.239).
# Mail is a special form of freight: its qualifying roll is keyed off the
# Freight Traffic DM computed for the same pair of worlds, bucketed into five
# tiers. Every roll is logged on +roller+ for a full audit trail.
class MailCalculator
  include HexDistance

  QUALIFYING_ROLL   = 12
  CONTAINER_TONS    = 5
  CONTAINER_PAYMENT = 25_000
  LOW_TECH_MAX      = 5

  attr_reader :roller, :result, :modifiers, :parsec_distance, :freight_traffic_dm

  def initialize(from_system:, to_system:, campaign:, ship_armed: false, naval_or_scout_rank: 0, soc_dm: 0,
                 referee_modifier: 0, seed: nil)
    @from_system         = from_system
    @to_system           = to_system
    @campaign            = campaign
    @dms                 = MailTrafficDms.for(campaign)
    @ship_armed          = ActiveModel::Type::Boolean.new.cast(ship_armed)
    @naval_or_scout_rank = naval_or_scout_rank.to_i
    @soc_dm              = soc_dm.to_i
    @referee_modifier    = referee_modifier.to_i
    @roller              = DiceRoller.new(seed: seed)
  end

  def calculate
    @parsec_distance    = hex_distance([@from_system.parsec.x, @from_system.parsec.y],
                                        [@to_system.parsec.x, @to_system.parsec.y])
    @freight_traffic_dm = compute_freight_traffic_dm
    @modifiers           = build_modifiers
    @result              = roll

    self
  end

  private

  def compute_freight_traffic_dm
    freight_dms = FreightTrafficDms.for(@campaign)
    world_modifiers = FreightTrafficCalculator.world_modifiers(@from_system, freight_dms) +
                       FreightTrafficCalculator.world_modifiers(@to_system, freight_dms)

    total = world_modifiers.sum { |m| m[:value] }
    total += freight_dms[:per_parsec] * (@parsec_distance - 1) if @parsec_distance > 1
    total
  end

  def tier_dm
    case @freight_traffic_dm
    when ..-10 then @dms[:freight_dm_very_low]
    when -9..-5 then @dms[:freight_dm_low]
    when -4..4 then @dms[:freight_dm_average]
    when 5..9 then @dms[:freight_dm_high]
    else @dms[:freight_dm_very_high]
    end
  end

  def low_tech_world?
    char = @from_system.main_world_uwp&.[](8)
    digit = char ? (HexDigit::HEX_DIGITS.index(char) || 0) : 0
    digit <= LOW_TECH_MAX
  end

  def build_modifiers
    modifiers = []
    modifiers << { label: "Freight Traffic DM (#{format('%+d', @freight_traffic_dm)})", value: tier_dm }
    modifiers << { label: 'Ship is armed', value: @dms[:ship_armed] } if @ship_armed
    modifiers << { label: 'Origin world TL 5 or less', value: @dms[:low_tech_world] } if low_tech_world?
    modifiers << { label: 'Naval/Scout Rank', value: @naval_or_scout_rank } if @naval_or_scout_rank != 0
    modifiers << { label: 'SOC DM', value: @soc_dm } if @soc_dm != 0
    modifiers << { label: 'Other DM', value: @referee_modifier } if @referee_modifier != 0
    modifiers
  end

  def roll
    total_dm = modifiers.sum { |m| m[:value] }
    qualifying_total = @roller.roll(n: 2, d: 6, dm: total_dm, note: 'Mail qualifying roll')
    qualifying_roll = roll_detail(qualifying_total)

    if qualifying_total < QUALIFYING_ROLL
      { available: false, containers: 0, total_tons: 0, total_payment: 0,
        qualifying_roll: qualifying_roll, containers_roll: nil }
    else
      containers_total = @roller.roll(n: 1, d: 6, dm: 0, note: 'Mail container count')
      containers_roll = roll_detail(containers_total)
      { available: true, containers: containers_total, total_tons: containers_total * CONTAINER_TONS,
        total_payment: containers_total * CONTAINER_PAYMENT,
        qualifying_roll: qualifying_roll, containers_roll: containers_roll }
    end
  end

  def roll_detail(total)
    @roller.log.last.merge(total: total)
  end
end
