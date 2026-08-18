require 'test_helper'

class StellarObjectsHelperTest < ActionView::TestCase
  include StellarObjectsHelper

  # flip_burn_travel_time_hours tests

  test 'flip_burn_travel_time_hours returns nil for nil distance' do
    assert_nil flip_burn_travel_time_hours(nil, 1)
  end

  test 'flip_burn_travel_time_hours returns nil for zero distance' do
    assert_nil flip_burn_travel_time_hours(0, 1)
  end

  test 'flip_burn_travel_time_hours returns nil for negative distance' do
    assert_nil flip_burn_travel_time_hours(-100, 1)
  end

  test 'flip_burn_travel_time_hours returns nil for nil g_rating' do
    assert_nil flip_burn_travel_time_hours(1000, nil)
  end

  test 'flip_burn_travel_time_hours returns nil for zero g_rating' do
    assert_nil flip_burn_travel_time_hours(1000, 0)
  end

  test 'flip_burn_travel_time_hours calculates correctly for 1G' do
    # 1,000,000 km at 1G
    # t = 2 * sqrt(d / a) where d = 1e9 m, a = 9.81 m/s²
    # t = 2 * sqrt(1e9 / 9.81) = 2 * 10098.5 = 20197 seconds = 5.61 hours
    result = flip_burn_travel_time_hours(1_000_000, 1)
    assert_in_delta 5.61, result, 0.01
  end

  test 'flip_burn_travel_time_hours is faster at higher G' do
    distance = 1_000_000
    time_1g = flip_burn_travel_time_hours(distance, 1)
    time_2g = flip_burn_travel_time_hours(distance, 2)
    time_6g = flip_burn_travel_time_hours(distance, 6)

    assert time_2g < time_1g, '2G should be faster than 1G'
    assert time_6g < time_2g, '6G should be faster than 2G'
  end

  test 'flip_burn_travel_time_hours scales with sqrt of distance' do
    time_short = flip_burn_travel_time_hours(1_000_000, 1)
    time_long = flip_burn_travel_time_hours(4_000_000, 1)

    # 4x distance should take 2x time (sqrt relationship)
    assert_in_delta time_short * 2, time_long, 0.01
  end

  # format_travel_time tests

  test 'format_travel_time returns dash for nil' do
    assert_equal '-', format_travel_time(nil)
  end

  test 'format_travel_time formats hours for values under 24' do
    assert_equal '5.6h', format_travel_time(5.61)
    assert_equal '1h', format_travel_time(1.0)
    assert_equal '23.9h', format_travel_time(23.9)
  end

  test 'format_travel_time formats days for values 24 and over' do
    assert_equal '1d', format_travel_time(24.0)
    assert_equal '2.5d', format_travel_time(60.0)
    assert_equal '10d', format_travel_time(240.0)
  end

  # jump_shadow_travel_times tests

  test 'jump_shadow_travel_times returns hash with 1-6 G ratings' do
    result = jump_shadow_travel_times(1_000_000)

    assert_equal 6, result.keys.length
    assert_equal [1, 2, 3, 4, 5, 6], result.keys
  end

  test 'jump_shadow_travel_times values decrease with higher G' do
    result = jump_shadow_travel_times(1_000_000)

    # Extract numeric values for comparison (strip h/d suffix)
    values = result.values.map { |v| v.to_f }

    (0..4).each do |i|
      assert values[i + 1] < values[i], "#{i + 2}G should be faster than #{i + 1}G"
    end
  end

  # kelvin_to_celsius tests

  test 'kelvin_to_celsius returns nil for nil input' do
    assert_nil kelvin_to_celsius(nil)
  end

  test 'kelvin_to_celsius converts 0K to -273.15C' do
    assert_in_delta(-273.15, kelvin_to_celsius(0), 0.001)
  end

  test 'kelvin_to_celsius converts 273.15K to 0C' do
    assert_in_delta 0, kelvin_to_celsius(273.15), 0.001
  end

  test 'kelvin_to_celsius converts 373.15K to 100C' do
    assert_in_delta 100, kelvin_to_celsius(373.15), 0.001
  end

  test 'kelvin_to_celsius converts typical planet temperature' do
    # Earth average ~288K = ~15C
    assert_in_delta 15, kelvin_to_celsius(288.15), 0.001
  end

  # format_temperature_celsius tests

  test 'format_temperature_celsius returns nil for nil input' do
    assert_nil format_temperature_celsius(nil)
  end

  test 'format_temperature_celsius formats freezing point' do
    assert_equal '0', format_temperature_celsius(273.15)
  end

  test 'format_temperature_celsius formats boiling point' do
    assert_equal '100', format_temperature_celsius(373.15)
  end

  test 'format_temperature_celsius formats negative temperatures' do
    # 200K = -73.15C, rounded to -73
    assert_equal '-73', format_temperature_celsius(200)
  end

  # population_display tests

  test 'population_display shows census population with delimiters when present' do
    assert_equal '1,234,567', population_display(6, 1_234_567)
  end

  test 'population_display falls back to population range when census population absent' do
    assert_equal population_range(6), population_display(6, nil)
  end

  test 'population_display returns nil when both census population and code are absent' do
    assert_nil population_display(nil, nil)
  end

  # format_credits tests

  test 'format_credits returns a dash for nil' do
    assert_equal '—', format_credits(nil)
  end

  test 'format_credits formats a value with the Cr unit' do
    assert_equal 'Cr500', format_credits(500)
  end

  # starport_fuel_cost_summary tests

  test 'starport_fuel_cost_summary shows refined cost first, then unrefined, unlabelled' do
    planet = TerrestrialPlanet.new(refined_fuel_cost: 500, unrefined_fuel_cost: 100)
    assert_equal 'Cr500 · Cr100', starport_fuel_cost_summary(planet)
  end

  test 'starport_fuel_cost_summary shows a dash in the refined position when refined is absent' do
    planet = TerrestrialPlanet.new(unrefined_fuel_cost: 100)
    assert_equal '— · Cr100', starport_fuel_cost_summary(planet)
  end

  test 'starport_fuel_cost_summary returns a dash when neither fuel grade is sold' do
    planet = TerrestrialPlanet.new
    assert_equal '—', starport_fuel_cost_summary(planet)
  end

  # starport_fuel_cost_display tooltip tests

  test 'starport_fuel_cost_display uses the unrefined-fuel-only tooltip when refined is absent' do
    planet = TerrestrialPlanet.new(unrefined_fuel_cost: 100)
    expected = '<span title="unrefined fuel only" class="cursor-help">— · Cr100</span>'
    assert_equal expected, starport_fuel_cost_display(planet).to_s
  end

  test 'starport_fuel_cost_display uses the generic tooltip when both grades are sold' do
    planet = TerrestrialPlanet.new(refined_fuel_cost: 500, unrefined_fuel_cost: 100)
    expected = '<span title="refined · unrefined" class="cursor-help">Cr500 · Cr100</span>'
    assert_equal expected, starport_fuel_cost_display(planet).to_s
  end

  test 'starport_fuel_cost_display uses the generic tooltip when neither grade is sold' do
    planet = TerrestrialPlanet.new
    expected = '<span title="refined · unrefined" class="cursor-help">—</span>'
    assert_equal expected, starport_fuel_cost_display(planet).to_s
  end

  # starport_costs_summary tests

  test 'starport_costs_summary puts berthing and fuel on separate lines' do
    planet = TerrestrialPlanet.new(berthing_cost: 6000, refined_fuel_cost: 500, unrefined_fuel_cost: 100)
    expected = 'Berthing Cr6,000<br>Fuel <span title="refined · unrefined" class="cursor-help">Cr500 · Cr100</span>'
    assert_equal expected, starport_costs_summary(planet).to_s
  end

  test 'starport_costs_summary shows a dash fuel line when no fuel is sold' do
    planet = TerrestrialPlanet.new(berthing_cost: 50)
    expected = 'Berthing Cr50<br>Fuel <span title="refined · unrefined" class="cursor-help">—</span>'
    assert_equal expected, starport_costs_summary(planet).to_s
  end

  test 'starport_costs_summary returns a single dash when there is no starport service at all' do
    planet = TerrestrialPlanet.new
    assert_equal '—', starport_costs_summary(planet)
  end
end
