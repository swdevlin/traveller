# frozen_string_literal: true

require 'test_helper'

class PassengerTrafficCalculatorTest < ActiveSupport::TestCase
  FakeParsec = Struct.new(:x, :y)
  FakeZone   = Struct.new(:code)
  FakeSystem = Struct.new(:main_world_uwp, :travel_zone, :parsec)

  setup do
    @campaign = campaigns(:one)
  end

  def build_system(uwp: nil, zone_code: nil, x: 0, y: 0)
    FakeSystem.new(uwp, zone_code && FakeZone.new(zone_code), FakeParsec.new(x, y))
  end

  def uwp_for(starport, population)
    "#{starport}788#{population}99-C"
  end

  def calculator(from:, to:, **opts)
    PassengerTrafficCalculator.new(from_system: from, to_system: to, campaign: @campaign, **opts).calculate
  end

  test 'population 1 or less applies the low-population DM' do
    from = build_system(uwp: uwp_for('C', 0), x: 0, y: 0)
    to   = build_system(uwp: uwp_for('C', 1), x: 0, y: 0)

    calc = calculator(from: from, to: to)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -4 }
    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (destination)', value: -4 }
  end

  test 'no main world is treated as population 0' do
    from = build_system(uwp: nil, x: 0, y: 0)
    to   = build_system(uwp: uwp_for('C', 8), x: 0, y: 0)

    calc = calculator(from: from, to: to)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -4 }
  end

  test 'population 6, 7 and 8 apply their respective DMs, and 2-5 defaults to 0' do
    six_world   = build_system(uwp: uwp_for('C', 6), x: 0, y: 0)
    eight_world = build_system(uwp: uwp_for('C', 8), x: 0, y: 0)
    none_world  = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: six_world, to: eight_world)
    assert_includes calc.shared_modifiers, { label: 'Population 6 (origin)', value: 1 }
    assert_includes calc.shared_modifiers, { label: 'Population 8 (destination)', value: 3 }

    calc = calculator(from: none_world, to: none_world.dup)
    refute calc.shared_modifiers.any? { |m| m[:label].start_with?('Population') }
  end

  test 'population digits above 9 are parsed from the UWP hex characters A, B and C' do
    ten_world    = build_system(uwp: uwp_for('C', 'A'), x: 0, y: 0)
    eleven_world = build_system(uwp: uwp_for('C', 'B'), x: 0, y: 0)
    twelve_world = build_system(uwp: uwp_for('C', 'C'), x: 0, y: 0)

    calc = calculator(from: ten_world, to: eleven_world)
    assert_includes calc.shared_modifiers, { label: 'Population 10 (origin)', value: 3 }
    assert_includes calc.shared_modifiers, { label: 'Population 11 (destination)', value: 3 }

    calc = calculator(from: twelve_world, to: twelve_world.dup)
    assert_includes calc.shared_modifiers, { label: 'Population 12 (origin)', value: 3 }
    assert_includes calc.shared_modifiers, { label: 'Population 12 (destination)', value: 3 }
  end

  test 'population 2-5 DM is overridable even though it defaults to 0' do
    @campaign.passenger_dm_population = ['', '', '-2', '', '', '', '', '', '', '', '', '']

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
    @campaign.passenger_dm_starport_c = -1
    @campaign.passenger_dm_starport_d = 2

    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('D', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Starport C (origin)', value: -1 }
    assert_includes calc.shared_modifiers, { label: 'Starport D (destination)', value: 2 }
  end

  test 'amber and red zone DMs apply' do
    origin = build_system(uwp: uwp_for('C', 3), zone_code: 'A', x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), zone_code: 'R', x: 0, y: 0)

    calc = calculator(from: origin, to: dest)
    assert_includes calc.shared_modifiers, { label: 'Amber Zone (origin)', value: 1 }
    assert_includes calc.shared_modifiers, { label: 'Red Zone (destination)', value: -4 }
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

  test 'rolling for High applies DM-4 and rolling for Low applies DM+1, only to that passenger type' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.results[:high][:modifiers], { label: 'Rolling for High', value: -4 }
    assert_includes calc.results[:low][:modifiers], { label: 'Rolling for Low', value: 1 }
    refute calc.results[:basic][:modifiers].any? { |m| m[:label].start_with?('Rolling for') }
    refute calc.results[:middle][:modifiers].any? { |m| m[:label].start_with?('Rolling for') }
  end

  test 'manual referee inputs are additive shared modifiers' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, broker_effect: 2, chief_steward_skill: 3, referee_modifier: -1)

    assert_includes calc.shared_modifiers, { label: 'Skill Effect', value: 2 }
    assert_includes calc.shared_modifiers, { label: 'Steward', value: 3 }
    assert_includes calc.shared_modifiers, { label: 'Other DM', value: -1 }
  end

  test 'campaign DM overrides are used instead of the sourcebook defaults' do
    @campaign.passenger_dm_population = ['-9', '', '', '', '', '', '', '', '', '', '', '']

    origin = build_system(uwp: uwp_for('C', 0), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest)

    assert_includes calc.shared_modifiers, { label: 'Population ≤1 (origin)', value: -9 }
  end

  test 'an overwhelmingly negative modifier deterministically yields 0 passengers with no count roll' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, referee_modifier: -30)

    PassengerTrafficCalculator::PASSENGER_TYPES.each do |type|
      result = calc.results[type]
      assert_equal 0, result[:passengers], type
      assert_operator result[:qualifying_roll][:total], :<=, 1, type
      assert_nil result[:count_roll], type
    end
  end

  test 'an overwhelmingly positive modifier deterministically clamps to the 20-or-more row' do
    origin = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)
    dest   = build_system(uwp: uwp_for('C', 3), x: 0, y: 0)

    calc = calculator(from: origin, to: dest, referee_modifier: 30)

    PassengerTrafficCalculator::PASSENGER_TYPES.each do |type|
      result = calc.results[type]
      assert_operator result[:qualifying_roll][:total], :>=, 20, type
      refute_nil result[:count_roll], type
      assert_equal 10, result[:count_roll][:dice], type
      assert_equal 6, result[:count_roll][:sides], type
      assert_equal result[:count_roll][:total], result[:passengers], type
      assert_includes 10..60, result[:passengers], type
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
