# frozen_string_literal: true

require 'test_helper'

class TradeAvailabilityCalculatorTest < ActiveSupport::TestCase
  FakePluckable = Struct.new(:values) do
    def pluck(_column) = values
  end
  FakeZone   = Struct.new(:code)
  FakeSystem = Struct.new(:main_world_uwp, :trade_codes, :travel_zone)

  setup do
    @campaign = campaigns(:one)
  end

  def build_system(uwp: nil, codes: [])
    FakeSystem.new(uwp, FakePluckable.new(codes), nil)
  end

  def uwp_for(starport, population)
    "#{starport}788#{population}99-C"
  end

  def calculator(system:, **opts)
    TradeAvailabilityCalculator.new(system: system, campaign: @campaign, **opts).calculate
  end

  test 'all six common goods are always guaranteed, regardless of trade codes' do
    system = build_system(uwp: uwp_for('C', 5), codes: [])

    calc = calculator(system: system)

    (11..16).each do |d66|
      good = calc.goods.find { |g| g[:d66] == d66 }
      refute_nil good, d66
      assert good[:guaranteed], d66
    end
  end

  test 'a trade good is guaranteed when its availability matches a world trade code' do
    system = build_system(uwp: uwp_for('C', 5), codes: %w[In Ht])

    calc = calculator(system: system)

    advanced_electronics = calc.goods.find { |g| g[:d66] == 21 }
    refute_nil advanced_electronics
    assert advanced_electronics[:guaranteed]
  end

  test 'a trade good is not guaranteed when no trade code matches' do
    system = build_system(uwp: uwp_for('C', 0), codes: [])

    calc = calculator(system: system)

    refute calc.goods.any? { |g| g[:d66] == 21 && g[:guaranteed] }
  end

  test 'population digit determines how many random D66 rolls are made' do
    system = build_system(uwp: uwp_for('C', 0), codes: [])
    calc = calculator(system: system)
    assert_equal 0, calc.population

    system = build_system(uwp: uwp_for('C', 8), codes: [])
    calc = calculator(system: system)
    assert_equal 8, calc.population
  end

  test 'low population applies DM-3 and high population applies DM+3 to tons rolls' do
    low  = calculator(system: build_system(uwp: uwp_for('C', 1)), seed: 7)
    high = calculator(system: build_system(uwp: uwp_for('C', 9)), seed: 7)

    low_electronics = low.goods.find { |g| g[:d66] == 11 }
    high_electronics = high.goods.find { |g| g[:d66] == 11 }

    assert_operator low_electronics[:tons], :<=, high_electronics[:tons]
  end

  test 'tons never go negative, even with an overwhelming low-population DM' do
    system = build_system(uwp: uwp_for('C', 1))

    calc = calculator(system: system)

    calc.goods.each { |g| assert_operator g[:tons], :>=, 0, g[:name] if g[:tons] }
  end

  test 'Exotics found via a random roll has no tons or price' do
    system = build_system(uwp: uwp_for('C', 12))

    exotics = nil
    seed = 0
    until exotics || seed > 200
      exotics = calculator(system: system, seed: seed).goods.find { |g| g[:d66] == 66 }
      seed += 1
    end

    refute_nil exotics, 'expected at least one of 200 seeds to roll Exotics with population 12'
    assert_nil exotics[:tons]
    assert_nil exotics[:base_price]
  end

  test 'base_price reflects a campaign override' do
    @campaign.trade_good_base_prices = { '11' => '99000' }
    system = build_system(uwp: uwp_for('C', 3))

    calc = calculator(system: system)

    assert_equal 99_000, calc.goods.find { |g| g[:d66] == 11 }[:base_price]
  end

  test 'the same seed produces an identical goods list' do
    system = build_system(uwp: uwp_for('A', 10), codes: %w[Ag Ri])

    first  = calculator(system: system, seed: 99)
    second = calculator(system: system, seed: 99)

    assert_equal first.goods, second.goods
  end

  test 'goods are always returned sorted by d66' do
    system = build_system(uwp: uwp_for('A', 10), codes: %w[Ag Ri In Ht])

    calc = calculator(system: system, seed: 3)

    assert_equal calc.goods.map { |g| g[:d66] }.sort, calc.goods.map { |g| g[:d66] }
  end
end
