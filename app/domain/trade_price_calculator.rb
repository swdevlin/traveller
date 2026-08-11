# frozen_string_literal: true

# Determines the Purchase or Sale price for one Trade Good at +system+,
# following the Determine Purchase Price / Selling Goods procedures (Mongoose
# Traveller 2e, p.243). Purchasing rolls 3D + Skill Effect + [largest matching
# Purchase DM] - [largest matching Sale DM] - Supplier Broker Skill; selling
# mirrors it with Sale/Purchase swapped and a Buyer Broker Skill. The result is
# looked up on the Modified Price table for a percentage of the good's Base
# Price. Every roll is logged on +roller+ for a full audit trail.
#
# +use_broker+ hires a local broker to negotiate instead of the Traveller: it
# replaces Skill Effect with a Local Broker DM of +broker_level+ + 2, and the
# resulting price is adjusted by +broker_fee_percentage+ into
# +net_price_per_ton+ (added to Purchase cost, deducted from Sale proceeds).
class TradePriceCalculator
  QUALIFYING_DICE = 3
  DIRECTIONS = %i[purchase sale].freeze

  attr_reader :roller, :result, :modifiers, :good

  def initialize(d66:, system:, campaign:, direction:, skill_effect: 0, counterpart_broker_skill: 2, other_dm: 0,
                 use_broker: false, broker_level: 2, broker_fee_percentage: 10, seed: nil)
    @good = TradeGoodsTable.for(d66.to_i)
    raise ArgumentError, "unknown d66: #{d66}" unless @good
    raise ArgumentError, 'Exotics has no computable price' if @good[:base_price].nil?

    @direction = direction.to_sym
    raise ArgumentError, 'direction must be :purchase or :sale' unless DIRECTIONS.include?(@direction)

    @system                   = system
    @campaign                 = campaign
    @skill_effect             = skill_effect.to_i
    @counterpart_broker_skill = counterpart_broker_skill.to_i
    @other_dm                 = other_dm.to_i
    @use_broker               = ActiveModel::Type::Boolean.new.cast(use_broker)
    @broker_level             = broker_level.to_i
    @broker_fee_percentage    = broker_fee_percentage.to_f
    @roller                   = DiceRoller.new(seed: seed)
  end

  def calculate
    @modifiers = build_modifiers
    @result    = roll

    self
  end

  private

  def codes
    @codes ||= @system.trade_codes.pluck(:code) + zone_codes
  end

  def zone_codes
    case @system.travel_zone&.code
    when 'A' then ['ZA']
    when 'R' then ['ZR']
    else []
    end
  end

  def largest_dm(dms)
    dms.values_at(*codes).compact.max || 0
  end

  def purchase_dm
    @purchase_dm ||= largest_dm(@good[:purchase_dms])
  end

  def sale_dm
    @sale_dm ||= largest_dm(@good[:sale_dms])
  end

  def build_modifiers
    modifiers = []

    if @use_broker
      modifiers << { label: 'Local Broker DM', value: @broker_level + 2 }
    elsif @skill_effect != 0
      modifiers << { label: 'Skill Effect', value: @skill_effect }
    end

    if @direction == :purchase
      modifiers << { label: 'Purchase DM', value: purchase_dm } if purchase_dm != 0
      modifiers << { label: 'Sale DM', value: -sale_dm } if sale_dm != 0
      modifiers << { label: 'Supplier Broker Skill', value: -@counterpart_broker_skill } if @counterpart_broker_skill != 0
    else
      modifiers << { label: 'Sale DM', value: sale_dm } if sale_dm != 0
      modifiers << { label: 'Purchase DM', value: -purchase_dm } if purchase_dm != 0
      modifiers << { label: 'Buyer Broker Skill', value: -@counterpart_broker_skill } if @counterpart_broker_skill != 0
    end

    modifiers << { label: 'Other DM', value: @other_dm } if @other_dm != 0
    modifiers
  end

  def roll
    total_dm = modifiers.sum { |m| m[:value] }
    total = @roller.roll(n: QUALIFYING_DICE, d: 6, dm: total_dm, note: "#{@good[:name]} #{@direction} roll")
    qualifying_roll = @roller.log.last.merge(total: total)

    base_price = TradeGoodPrices.base_price_for(@good[:d66], @campaign)
    percent = @direction == :purchase ? ModifiedPriceTable.purchase_percent(total) : ModifiedPriceTable.sale_percent(total)
    price_per_ton = (base_price * percent / 100.0).round

    fee_percentage = @use_broker ? @broker_fee_percentage : 0
    fee = price_per_ton * fee_percentage / 100.0
    net_price_per_ton = (@direction == :purchase ? price_per_ton + fee : price_per_ton - fee).round

    { base_price: base_price, percent: percent, price_per_ton: price_per_ton, net_price_per_ton: net_price_per_ton,
      fee_percentage: fee_percentage, qualifying_roll: qualifying_roll }
  end
end
