# frozen_string_literal: true

require 'test_helper'

class MailCalculatorTest < ActiveSupport::TestCase
  FakeParsec = Struct.new(:x, :y)
  FakeZone   = Struct.new(:code)
  FakeSystem = Struct.new(:main_world_uwp, :travel_zone, :parsec)

  setup do
    @campaign = campaigns(:one)
  end

  def build_system(uwp: nil, zone_code: nil, x: 0, y: 0)
    FakeSystem.new(uwp, zone_code && FakeZone.new(zone_code), FakeParsec.new(x, y))
  end

  def uwp_for(starport, population, tech_level: '7')
    "#{starport}788#{population}99-#{tech_level}"
  end

  def calculator(from:, to:, **opts)
    MailCalculator.new(from_system: from, to_system: to, campaign: @campaign, **opts).calculate
  end

  def neutral_system(x: 0, y: 0)
    build_system(uwp: uwp_for('C', 3, tech_level: '7'), x: x, y: y)
  end

  test 'a neutral pair of worlds falls in the average Freight Traffic DM tier' do
    from = neutral_system
    to   = neutral_system

    calc = calculator(from: from, to: to)

    assert_equal 0, calc.freight_traffic_dm
    assert_includes calc.modifiers, { label: 'Freight Traffic DM (+0)', value: 0 }
  end

  test 'a strongly negative pair of worlds falls in the very low Freight Traffic DM tier' do
    from = build_system(uwp: uwp_for('X', 0, tech_level: '0'))
    to   = build_system(uwp: uwp_for('X', 0, tech_level: '0'))

    calc = calculator(from: from, to: to)

    assert_operator calc.freight_traffic_dm, :<=, -10
    assert_includes calc.modifiers, { label: "Freight Traffic DM (#{format('%+d', calc.freight_traffic_dm)})", value: -2 }
  end

  test 'a moderately negative pair of worlds falls in the low Freight Traffic DM tier' do
    from = neutral_system
    to   = build_system(uwp: uwp_for('X', 0, tech_level: '0'))

    calc = calculator(from: from, to: to)

    assert_includes(-9..-5, calc.freight_traffic_dm)
    assert_includes calc.modifiers, { label: "Freight Traffic DM (#{format('%+d', calc.freight_traffic_dm)})", value: -1 }
  end

  test 'a moderately positive pair of worlds falls in the high Freight Traffic DM tier' do
    from = neutral_system
    to   = build_system(uwp: uwp_for('A', 8, tech_level: '7'))

    calc = calculator(from: from, to: to)

    assert_includes(5..9, calc.freight_traffic_dm)
    assert_includes calc.modifiers, { label: "Freight Traffic DM (#{format('%+d', calc.freight_traffic_dm)})", value: 1 }
  end

  test 'a strongly positive pair of worlds falls in the very high Freight Traffic DM tier' do
    from = build_system(uwp: uwp_for('A', 8, tech_level: '9'))
    to   = build_system(uwp: uwp_for('A', 8, tech_level: '9'))

    calc = calculator(from: from, to: to)

    assert_operator calc.freight_traffic_dm, :>=, 10
    assert_includes calc.modifiers, { label: "Freight Traffic DM (#{format('%+d', calc.freight_traffic_dm)})", value: 2 }
  end

  test 'an armed ship applies its DM' do
    calc = calculator(from: neutral_system, to: neutral_system, ship_armed: true)

    assert_includes calc.modifiers, { label: 'Ship is armed', value: 2 }
  end

  test 'an unarmed ship does not apply the armed DM' do
    calc = calculator(from: neutral_system, to: neutral_system, ship_armed: false)

    refute calc.modifiers.any? { |m| m[:label] == 'Ship is armed' }
  end

  test 'a low tech origin world applies its DM, but the destination tech level is irrelevant' do
    from = build_system(uwp: uwp_for('C', 3, tech_level: '5'))
    to   = build_system(uwp: uwp_for('C', 3, tech_level: 'F'))

    calc = calculator(from: from, to: to)

    assert_includes calc.modifiers, { label: 'Origin world TL 5 or less', value: -4 }
  end

  test 'a high tech origin world does not apply the low tech DM' do
    from = build_system(uwp: uwp_for('C', 3, tech_level: '6'))
    to   = neutral_system

    calc = calculator(from: from, to: to)

    refute calc.modifiers.any? { |m| m[:label] == 'Origin world TL 5 or less' }
  end

  test 'manual referee inputs are additive modifiers' do
    calc = calculator(from: neutral_system, to: neutral_system,
                       naval_or_scout_rank: 3, soc_dm: 1, referee_modifier: -2)

    assert_includes calc.modifiers, { label: 'Naval/Scout Rank', value: 3 }
    assert_includes calc.modifiers, { label: 'SOC DM', value: 1 }
    assert_includes calc.modifiers, { label: 'Other DM', value: -2 }
  end

  test 'a qualifying roll below 12 finds no mail available' do
    calc = calculator(from: neutral_system, to: neutral_system, referee_modifier: -30)

    refute calc.result[:available]
    assert_equal 0, calc.result[:containers]
    assert_equal 0, calc.result[:total_tons]
    assert_equal 0, calc.result[:total_payment]
    assert_nil calc.result[:containers_roll]
  end

  test 'a qualifying roll of 12 or more finds mail available, priced flat per container' do
    calc = calculator(from: neutral_system, to: neutral_system, referee_modifier: 30)

    assert calc.result[:available]
    assert_operator calc.result[:containers], :>=, 1
    refute_nil calc.result[:containers_roll]
    assert_equal 1, calc.result[:containers_roll][:dice]
    assert_equal 6, calc.result[:containers_roll][:sides]
    assert_equal calc.result[:containers] * MailCalculator::CONTAINER_TONS, calc.result[:total_tons]
    assert_equal calc.result[:containers] * MailCalculator::CONTAINER_PAYMENT, calc.result[:total_payment]
  end

  test 'the same seed produces identical results' do
    from = build_system(uwp: uwp_for('C', 8, tech_level: '9'), zone_code: 'A', x: 0, y: 0)
    to   = build_system(uwp: uwp_for('A', 6, tech_level: '3'), zone_code: 'R', x: 6, y: 0)

    first  = calculator(from: from, to: to, seed: 42)
    second = calculator(from: from, to: to, seed: 42)

    assert_equal first.result, second.result
  end
end
