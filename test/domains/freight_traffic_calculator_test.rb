# frozen_string_literal: true

require 'test_helper'

class FreightTrafficCalculatorTest < ActiveSupport::TestCase
  FakeParsec = Struct.new(:x, :y)
  FakeZone   = Struct.new(:code)
  FakeSystem = Struct.new(:main_world_uwp, :travel_zone, :parsec)

  setup do
    @campaign = campaigns(:one)
  end

  def build_system(uwp: nil, zone_code: nil, x: 0, y: 0)
    FakeSystem.new(uwp, zone_code && FakeZone.new(zone_code), FakeParsec.new(x, y))
  end

  def uwp_for(starport, population, tech_level: 'C')
    "#{starport}788#{population}99-#{tech_level}"
  end

  def calculator(from:, to:, **opts)
    FreightTrafficCalculator.new(from_system: from, to_system: to, campaign: @campaign, **opts).calculate
  end

  test 'population 1 or less applies the low-population DM' do
    from = build_system(uwp: uwp_for('C', 0), x: 0, y: 0)
    to   = build_system(uwp: uwp_for('C', 1), x: 0, y: 0)

    calc = calculator(from: from, to: to)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -4 }
    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (destination)', value: -4 }
  end

  test 'no main world is treated as population 0 and tech level 0' do
    from = build_system(uwp: nil, x: 0, y: 0)
    to   = build_system(uwp: uwp_for('C', 8), x: 0, y: 0)

    calc = calculator(from: from, to: to)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -4 }
    assert_includes calc.shared_modifiers, { label: 'Tech Level 0 (origin)', value: -1 }
  end

  test 'population 6, 7 and 8 apply their respective DMs, and 2-5 defaults to 0' do
    six_world   = build_system(uwp: uwp_for('C', 6), x: 0, y: 0)
    eight_world = build_system(uwp: uwp_for('C', 8), x: 0, y: 0)
    none_world  = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: six_world, to: eight_world)
    assert_includes calc.shared_modifiers, { label: 'Population 6 (origin)', value: 2 }
    assert_includes calc.shared_modifiers, { label: 'Population 8 (destination)', value: 4 }

    calc = calculator(from: none_world, to: none_world.dup)
    refute calc.shared_modifiers.any? { |m| m[:label].start_with?('Population') }
  end

  test 'population digits above 9 are parsed from the UWP hex characters A, B and C' do
    ten_world    = build_system(uwp: uwp_for('C', 'A'), x: 0, y: 0)
    eleven_world = build_system(uwp: uwp_for('C', 'B'), x: 0, y: 0)
    twelve_world = build_system(uwp: uwp_for('C', 'C'), x: 0, y: 0)

    calc = calculator(from: ten_world, to: eleven_world)
    assert_includes calc.shared_modifiers, { label: 'Population 10 (origin)', value: 4 }
    assert_includes calc.shared_modifiers, { label: 'Population 11 (destination)', value: 4 }

    calc = calculator(from: twelve_world, to: twelve_world.dup)
    assert_includes calc.shared_modifiers, { label: 'Population 12 (origin)', value: 4 }
  end

  test 'population 2-5 DM is overridable even though it defaults to 0' do
    @campaign.freight_dm_population = ['', '', '-2', '', '', '', '', '', '', '', '', '']

    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Population 3 (origin)', value: -2 }
    assert_includes calc.shared_modifiers, { label: 'Population 3 (destination)', value: -2 }
  end

  test 'starport DMs apply for A, B, E and X, and default to 0 for C and D' do
    origin = build_system(uwp: uwp_for('A', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('X', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)
    assert_includes calc.shared_modifiers, { label: 'Starport A (origin)', value: 2 }
    assert_includes calc.shared_modifiers, { label: 'Starport X (destination)', value: -3 }

    neutral = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    calc = calculator(from: neutral, to: neutral.dup)
    refute calc.shared_modifiers.any? { |m| m[:label].start_with?('Starport') }
  end

  test 'starport C and D DMs are overridable even though they default to 0' do
    @campaign.freight_dm_starport_c = -1
    @campaign.freight_dm_starport_d = 2

    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('D', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Starport C (origin)', value: -1 }
    assert_includes calc.shared_modifiers, { label: 'Starport D (destination)', value: 2 }
  end

  test 'tech level 6 or less applies DM-1, 9 or more applies DM+2, and 7-8 defaults to 0' do
    low_world  = build_system(uwp: uwp_for('C', 3, tech_level: '6'), x: 0, y: 0)
    high_world = build_system(uwp: uwp_for('C', 3, tech_level: '9'), x: 0, y: 0)
    mid_world  = build_system(uwp: uwp_for('C', 3, tech_level: '7'), x: 0, y: 0)

    calc = calculator(from: low_world, to: high_world)
    assert_includes calc.shared_modifiers, { label: 'Tech Level 6 (origin)', value: -1 }
    assert_includes calc.shared_modifiers, { label: 'Tech Level 9 (destination)', value: 2 }

    calc = calculator(from: mid_world, to: mid_world.dup)
    refute calc.shared_modifiers.any? { |m| m[:label].start_with?('Tech Level') }
  end

  test 'tech level 7-8 DM is overridable even though it defaults to 0' do
    @campaign.freight_dm_tech_level = ([''] * 7) + ['-3'] + ([''] * 9)

    origin = build_system(uwp: uwp_for('C', 3, tech_level: '7'), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3, tech_level: '7'), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Tech Level 7 (origin)', value: -3 }
    assert_includes calc.shared_modifiers, { label: 'Tech Level 7 (destination)', value: -3 }
  end

  test 'amber and red zone DMs apply' do
    origin = build_system(uwp: uwp_for('C', 3), zone_code: 'A', x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), zone_code: 'R', x: 0, y: 0)

    calc = calculator(from: origin, to: dest)
    assert_includes calc.shared_modifiers, { label: 'Amber Zone (origin)', value: -2 }
    assert_includes calc.shared_modifiers, { label: 'Red Zone (destination)', value: -6 }
  end

  test 'distance DM applies -1 per parsec beyond the first, and none for 0 or 1 parsec' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    adjacent_ish = build_system(uwp: uwp_for('C', 3), x: 4, y: 0)

    calc = calculator(from: origin, to: adjacent_ish)
    assert_equal 4, calc.parsec_distance
    assert_includes calc.shared_modifiers, { label: 'Distance 4 parsecs', value: -3 }

    same = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    calc = calculator(from: origin, to: same)
    assert_equal 0, calc.parsec_distance
    refute calc.shared_modifiers.any? { |m| m[:label].start_with?('Distance') }
  end

  test 'rolling for Major Cargo applies DM-4 and Incidental Cargo applies DM+2, only to that lot type' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.results[:major][:modifiers], { label: 'Rolling for Major Cargo', value: -4 }
    assert_includes calc.results[:incidental][:modifiers], { label: 'Rolling for Incidental Cargo', value: 2 }
    refute calc.results[:minor][:modifiers].any? { |m| m[:label].start_with?('Rolling for') }
  end

  test 'manual referee inputs are additive shared modifiers' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, broker_effect: 2, referee_modifier: -1)

    assert_includes calc.shared_modifiers, { label: 'Skill Effect', value: 2 }
    assert_includes calc.shared_modifiers, { label: 'Other DM', value: -1 }
  end

  test 'campaign DM overrides are used instead of the sourcebook defaults' do
    @campaign.freight_dm_population = ['-9', '', '', '', '', '', '', '', '', '', '', '']

    origin = build_system(uwp: uwp_for('C', 0), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -9 }
  end

  test 'an overwhelmingly negative modifier deterministically yields 0 lots with no lots roll' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, referee_modifier: -30)

    FreightTrafficCalculator::LOT_TYPES.each do |type|
      result = calc.results[type]
      assert_equal 0, result[:lots], type
      assert_equal 0, result[:total_tons], type
      assert_empty result[:lot_size_rolls], type
      assert_operator result[:qualifying_roll][:total], :<=, 1, type
      assert_nil result[:lots_roll], type
    end
  end

  test 'an overwhelmingly positive modifier deterministically clamps to the 20-or-more row' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, referee_modifier: 30)

    FreightTrafficCalculator::LOT_TYPES.each do |type|
      result = calc.results[type]
      assert_operator result[:qualifying_roll][:total], :>=, 20, type
      refute_nil result[:lots_roll], type
      assert_equal 10, result[:lots_roll][:dice], type
      assert_equal 6, result[:lots_roll][:sides], type
      assert_equal result[:lots_roll][:total], result[:lots], type
      assert_equal result[:lots], result[:lot_size_rolls].length, type
      assert_equal result[:lot_size_rolls].sum { |r| r[:tons] }, result[:total_tons], type
    end
  end

  test 'lot sizes are multiplied per type: incidental x1, minor x5, major x10' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, referee_modifier: 30)

    multipliers = { incidental: 1, minor: 5, major: 10 }
    FreightTrafficCalculator::LOT_TYPES.each do |type|
      calc.results[type][:lot_size_rolls].each do |roll|
        assert_equal roll[:total] * multipliers[type], roll[:tons], type
      end
    end
  end

  test 'the same seed produces identical results' do
    origin = build_system(uwp: uwp_for('C', 8), zone_code: 'A', x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('A', 6), zone_code: 'R', x: 6, y: 0)

    first  = calculator(from: origin, to: dest, seed: 42)
    second = calculator(from: origin, to: dest, seed: 42)

    assert_equal first.results, second.results
  end
end
