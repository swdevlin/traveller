# frozen_string_literal: true

# Determines which speculative trade goods are available for purchase at
# +system+, following the Determine Goods Available procedure (Mongoose Traveller
# 2e, p.242). Every market has all Common Goods (D66 11-16) plus any Trade Goods
# whose Availability trade codes match the world, plus a number of additional
# goods equal to the world's Population digit, each found by a 1D66 roll on the
# full table. Every present good rolls its own Tons dice code for quantity
# (repeated per occurrence — rolling the same good more than once adds extra
# tons rather than duplicating the entry), with a DM applied for population
# extremes. Every roll is logged on +roller+ for a full audit trail.
#
# Determinism note: goods are always processed in ascending d66 order once the
# full set (guaranteed + randomly found) is known, so the same +seed+ always
# consumes the roller in the same sequence and produces an identical result —
# this is what lets CommerceController re-render the same goods list across
# repeated page loads by threading the seed through a hidden field.
class TradeAvailabilityCalculator
  LOW_POPULATION_MAX  = 3
  HIGH_POPULATION_MIN = 9

  attr_reader :roller, :goods, :trade_codes, :population

  def initialize(system:, campaign:, seed: nil)
    @system   = system
    @campaign = campaign
    @roller   = DiceRoller.new(seed: seed)
  end

  def calculate
    @trade_codes = @system.trade_codes.pluck(:code)
    @population  = population_digit
    @goods       = build_goods

    self
  end

  private

  def population_digit
    char = @system.main_world_uwp&.[](4)
    char ? (HexDigit::HEX_DIGITS.index(char) || 0) : 0
  end

  def quantity_dm
    return -3 if population <= LOW_POPULATION_MAX
    return 3 if population >= HIGH_POPULATION_MIN

    0
  end

  def guaranteed_d66s
    common = (11..16).to_a
    matching = TradeGoodsTable.all.select do |row|
      row[:availability].is_a?(Array) && (row[:availability] & trade_codes).any?
    end.map { |row| row[:d66] }

    common + matching
  end

  def build_goods
    rolls_needed = Hash.new(0)
    guaranteed = guaranteed_d66s
    guaranteed.each { |d66| rolls_needed[d66] += 1 }
    population.times { rolls_needed[roll_d66] += 1 }

    rolls_needed.keys.sort.map do |d66|
      row = TradeGoodsTable.for(d66)
      occurrences = rolls_needed[d66]

      {
        d66: d66,
        name: row[:name],
        category: row[:category],
        guaranteed: guaranteed.include?(d66),
        tons: row[:tons_dice] ? occurrences.times.sum { roll_tons(row) } : nil,
        base_price: TradeGoodPrices.base_price_for(d66, @campaign)
      }
    end
  end

  def roll_d66
    tens  = @roller.roll(n: 1, d: 6, dm: 0, note: 'D66 tens digit')
    units = @roller.roll(n: 1, d: 6, dm: 0, note: 'D66 units digit')
    (tens * 10) + units
  end

  def roll_tons(row)
    count, multiplier = row[:tons_dice]
    total = @roller.roll(n: count, d: 6, dm: quantity_dm, note: "#{row[:name]} tons")
    [total, 0].max * multiplier
  end
end
