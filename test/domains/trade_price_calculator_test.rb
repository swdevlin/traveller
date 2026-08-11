# frozen_string_literal: true

require 'test_helper'

class TradePriceCalculatorTest < ActiveSupport::TestCase
  FakePluckable = Struct.new(:values) do
    def pluck(_column) = values
  end
  FakeZone   = Struct.new(:code)
  FakeSystem = Struct.new(:trade_codes, :travel_zone)

  setup do
    @campaign = campaigns(:one)
  end

  def build_system(codes: [], zone_code: nil)
    FakeSystem.new(FakePluckable.new(codes), zone_code && FakeZone.new(zone_code))
  end

  def calculator(d66:, system:, direction:, **opts)
    TradePriceCalculator.new(d66: d66, system: system, campaign: @campaign, direction: direction, **opts).calculate
  end

  test 'raises for an unknown d66' do
    assert_raises(ArgumentError) { calculator(d66: 999, system: build_system, direction: :purchase) }
  end

  test 'raises for Exotics, which has no computable price' do
    assert_raises(ArgumentError) { calculator(d66: 66, system: build_system, direction: :purchase) }
  end

  test 'raises for an invalid direction' do
    assert_raises(ArgumentError) { calculator(d66: 11, system: build_system, direction: :browse) }
  end

  test 'purchase uses the largest matching Purchase DM among the world trade codes' do
    system = build_system(codes: %w[In Ht Ri])

    calc = calculator(d66: 11, system: system, direction: :purchase)

    assert_includes calc.modifiers, { label: 'Purchase DM', value: 3 }
  end

  test 'purchase subtracts the largest matching Sale DM' do
    system = build_system(codes: %w[Ni Lt Po])

    calc = calculator(d66: 11, system: system, direction: :purchase)

    assert_includes calc.modifiers, { label: 'Sale DM', value: -2 }
  end

  test 'sale uses the largest matching Sale DM and subtracts the largest matching Purchase DM' do
    system = build_system(codes: %w[In Ht Ri Ni Lt Po])

    calc = calculator(d66: 11, system: system, direction: :sale)

    assert_includes calc.modifiers, { label: 'Sale DM', value: 2 }
    assert_includes calc.modifiers, { label: 'Purchase DM', value: -3 }
  end

  test 'travel zone DMs are matched via ZA/ZR synthetic codes' do
    system = build_system(zone_code: 'R')

    calc = calculator(d66: 24, system: system, direction: :sale)

    assert_includes calc.modifiers, { label: 'Sale DM', value: 4 }
  end

  test 'default counterpart broker skill of 2 is subtracted' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase)

    assert_includes calc.modifiers, { label: 'Supplier Broker Skill', value: -2 }
  end

  test 'skill effect and other DM are additive' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase, skill_effect: 2, other_dm: -1)

    assert_includes calc.modifiers, { label: 'Skill Effect', value: 2 }
    assert_includes calc.modifiers, { label: 'Other DM', value: -1 }
  end

  test 'result percent and price_per_ton follow the Modified Price table' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase, other_dm: 30)

    assert_equal 20_000, calc.result[:base_price]
    assert_equal 15, calc.result[:percent]
    assert_equal 3_000, calc.result[:price_per_ton]
  end

  test 'base_price reflects a campaign override' do
    @campaign.trade_good_base_prices = { '11' => '50000' }
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase)

    assert_equal 50_000, calc.result[:base_price]
  end

  test 'the same seed produces an identical result' do
    system = build_system(codes: %w[In Ht])

    first  = calculator(d66: 21, system: system, direction: :purchase, seed: 5)
    second = calculator(d66: 21, system: system, direction: :purchase, seed: 5)

    assert_equal first.result, second.result
  end

  test 'using a local broker replaces Skill Effect with a Local Broker DM of level + 2' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase, skill_effect: 5, use_broker: true,
                       broker_level: 3)

    assert_includes calc.modifiers, { label: 'Local Broker DM', value: 5 }
    refute(calc.modifiers.any? { |m| m[:label] == 'Skill Effect' })
  end

  test 'without a local broker, net_price_per_ton equals price_per_ton' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase, other_dm: 30)

    assert_equal calc.result[:price_per_ton], calc.result[:net_price_per_ton]
    assert_equal 0, calc.result[:fee_percentage]
  end

  test 'local broker fee is added to net_price_per_ton on purchase' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :purchase, other_dm: 30, use_broker: true,
                       broker_level: 2, broker_fee_percentage: 10)

    assert_equal 3_000, calc.result[:price_per_ton]
    assert_equal 3_300, calc.result[:net_price_per_ton]
    assert_equal 10, calc.result[:fee_percentage]
  end

  test 'local broker fee is deducted from net_price_per_ton on sale' do
    system = build_system

    calc = calculator(d66: 11, system: system, direction: :sale, other_dm: 30, use_broker: true,
                       broker_level: 2, broker_fee_percentage: 10)

    assert_equal 80_000, calc.result[:price_per_ton]
    assert_equal 72_000, calc.result[:net_price_per_ton]
  end
end
