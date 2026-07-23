require 'test_helper'

class RouteTimingTest < ActiveSupport::TestCase
  include JumpShadowMath

  def setup
    @sector = Sector.create!(name: 'Route Timing Test Sector', x: 90, y: 90, abbreviation: 'Rtt')
  end

  def build_system_with_main_world(x, y, diameter:)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    system = StarSystem.create!(name: "System #{x},#{y}", parsec: parsec)
    star = Star.create!(star_system: system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V')
    world = TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0, diameter: diameter,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5
    )
    system.update!(main_world: world)
    system
  end

  def build_system_without_main_world(x, y, star_jump_shadow:)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    system = StarSystem.create!(name: "System #{x},#{y}", parsec: parsec)
    Star.create!(
      star_system: system, colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V',
      data: { 'jump_shadow' => star_jump_shadow }
    )
    system
  end

  test 'the origin has its own transit time (the departure leg away from that world)' do
    a = build_system_with_main_world(0, 0, diameter: 10_000)
    b = build_system_with_main_world(1, 0, diameter: 10_000)

    timings = RouteTiming.new(m_drive: 1).timings_for([a, b])

    expected = flip_burn_travel_time_hours(a.main_world.effective_jump_shadow_km, 1)
    assert_in_delta expected, timings.first.transit_hours, 0.001
  end

  test 'the origin has elapsed_avg_hours equal to its own transit time, not nil' do
    a = build_system_with_main_world(0, 0, diameter: 10_000)
    b = build_system_with_main_world(1, 0, diameter: 10_000)

    timings = RouteTiming.new(m_drive: 1).timings_for([a, b])

    assert_equal timings.first.transit_hours, timings.first.elapsed_avg_hours
  end

  test 'transit_hours is the same value whether a system is an origin or a destination' do
    a = build_system_with_main_world(0, 0, diameter: 40_000)
    b = build_system_with_main_world(2, 0, diameter: 40_000)

    forward = RouteTiming.new(m_drive: 1).timings_for([a, b])
    reverse = RouteTiming.new(m_drive: 1).timings_for([b, a])

    assert_in_delta forward.first.transit_hours, reverse.second.transit_hours, 0.001
  end

  test 'falls back to the primary star jump shadow when no main_world is set' do
    a = build_system_without_main_world(0, 0, star_jump_shadow: 50_000)
    b = build_system_with_main_world(1, 0, diameter: 10_000)

    timing = RouteTiming.new(m_drive: 2)
    row = timing.timings_for([a, b]).first

    expected = flip_burn_travel_time_hours(50_000, 2)
    assert_in_delta expected, row.transit_hours, 0.001
  end

  test 'jump duration constants follow 148 + 6D hours' do
    assert_equal 169.0, RouteTiming::JUMP_AVG_HOURS
    assert_equal 154.0, RouteTiming::JUMP_MIN_HOURS
    assert_equal 184.0, RouteTiming::JUMP_MAX_HOURS
  end

  test 'elapsed_avg_hours accumulates transit plus jump plus transit across hops, double-counting intermediate stops' do
    a = build_system_with_main_world(0, 0, diameter: 10_000)
    b = build_system_with_main_world(1, 0, diameter: 20_000)
    c = build_system_with_main_world(2, 0, diameter: 10_000)

    timings = RouteTiming.new(m_drive: 1).timings_for([a, b, c])
    origin, middle, destination = timings

    assert_in_delta origin.transit_hours, origin.elapsed_avg_hours, 0.001

    expected_middle = origin.transit_hours + RouteTiming::JUMP_AVG_HOURS + middle.transit_hours
    assert_in_delta expected_middle, middle.elapsed_avg_hours, 0.001

    expected_destination = expected_middle + middle.transit_hours + RouteTiming::JUMP_AVG_HOURS + destination.transit_hours
    assert_in_delta expected_destination, destination.elapsed_avg_hours, 0.001
  end

  test 'total splits jump (avg/min/max) from the deterministic transit sum, counting intermediates twice' do
    a = build_system_with_main_world(0, 0, diameter: 10_000)
    b = build_system_with_main_world(1, 0, diameter: 20_000)
    c = build_system_with_main_world(2, 0, diameter: 10_000)

    timing = RouteTiming.new(m_drive: 1)
    timings = timing.timings_for([a, b, c])
    total = timing.total(timings)

    assert_in_delta 2 * RouteTiming::JUMP_AVG_HOURS, total[:jump_avg_hours], 0.001
    assert_in_delta 2 * RouteTiming::JUMP_MIN_HOURS, total[:jump_min_hours], 0.001
    assert_in_delta 2 * RouteTiming::JUMP_MAX_HOURS, total[:jump_max_hours], 0.001

    origin, middle, destination = timings
    expected_transit = origin.transit_hours + (2 * middle.transit_hours) + destination.transit_hours
    assert_in_delta expected_transit, total[:transit_hours], 0.001

    assert_in_delta total[:jump_avg_hours] + total[:transit_hours], total[:total_avg_hours], 0.001
    assert_in_delta total[:jump_min_hours] + total[:transit_hours], total[:total_min_hours], 0.001
    assert_in_delta total[:jump_max_hours] + total[:transit_hours], total[:total_max_hours], 0.001
  end
end
