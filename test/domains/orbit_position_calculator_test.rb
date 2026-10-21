require 'test_helper'

class OrbitPositionCalculatorTest < ActiveSupport::TestCase
  # Stands in for Random, handing back the generator's draws in order.
  class FixedRandom
    def initialize(*draws)
      @draws = draws
    end

    def rand(_range)
      @draws.shift
    end
  end

  def planet(x: 0, y: 0)
    Planetoid.new(diameter: 12_000, orbit_x: x, orbit_y: y)
  end

  test 'matches the generator for identical draws' do
    # Expected values come from running system-generation's moonOrbitPosition with the same draws.
    moon = Moon.new(orbit: 12.5, eccentricity: 0.3, inclination: 5)
    position = OrbitPositionCalculator.for_moon(moon: moon, planet: planet(x: 150_000_000, y: -80_000_000),
                                     random: FixedRandom.new(40, 100, 1.5))

    assert_in_delta 149_970_032.73270777, position.x, 1e-6
    assert_in_delta(-80_157_068.42029144, position.y, 1e-6)
    assert_in_delta 159_901.61275550592, position.radius, 1e-6
    assert_in_delta 1.7926475365684045, position.eccentric_anomaly, 1e-12
  end

  test 'circular orbit is the orbit distance from the planet' do
    moon = Moon.new(orbit: 10, eccentricity: 0)
    position = OrbitPositionCalculator.for_moon(moon: moon, planet: planet(x: 5_000, y: 7_000))

    assert_in_delta 120_000, Math.hypot(position.x - 5_000, position.y - 7_000), 1e-6
  end

  test 'eccentric orbit stays between periapsis and apoapsis' do
    moon = Moon.new(orbit: 10, eccentricity: 0.4)
    20.times do
      position = OrbitPositionCalculator.for_moon(moon: moon, planet: planet)

      assert_operator Math.hypot(position.x, position.y), :>=, position.periapsis - 1e-6
      assert_operator Math.hypot(position.x, position.y), :<=, position.apoapsis + 1e-6
    end
  end

  test 'draws once so an instance is stable' do
    position = OrbitPositionCalculator.for_moon(moon: Moon.new(orbit: 3, eccentricity: 0.2), planet: planet)

    assert_equal position.x, position.x
    assert_equal position.y, position.y
  end

  test 'a moon has no position without an orbit or planet diameter' do
    assert_nil OrbitPositionCalculator.for_moon(moon: Moon.new, planet: planet)
    assert_nil OrbitPositionCalculator.for_moon(moon: Moon.new(orbit: 2), planet: Planetoid.new)
  end

  test 'a moon has no position when the planet has no position' do
    assert_nil OrbitPositionCalculator.for_moon(moon: Moon.new(orbit: 2), planet: Planetoid.new(diameter: 12_000))
  end

  test 'a body orbiting a star is placed by its orbit number around the star' do
    star = Star.new(orbit_x: 1_000, orbit_y: -2_000)
    body = GasGiant.new(orbit: 5, eccentricity: 0)
    position = OrbitPositionCalculator.for_body_orbiting_star(body: body, star: star)

    expected = OrbitToAu.convert(5) * StellarConstants::AU_TO_KM
    assert_in_delta expected, Math.hypot(position.x - 1_000, position.y + 2_000), 1e-3
  end

  test 'the primary star, which has no position, is the origin' do
    position = OrbitPositionCalculator.for_body_orbiting_star(body: GasGiant.new(orbit: 5, eccentricity: 0), star: Star.new)

    assert_in_delta OrbitToAu.convert(5) * StellarConstants::AU_TO_KM, Math.hypot(position.x, position.y), 1e-3
  end

  test 'a body orbiting a star has no position without an orbit' do
    assert_nil OrbitPositionCalculator.for_body_orbiting_star(body: GasGiant.new, star: Star.new)
  end
end
