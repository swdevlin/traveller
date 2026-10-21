require 'test_helper'

class HasOrbitTest < ActiveSupport::TestCase
  test 'orbit_distance_from_parent_km takes the parent position off the absolute position' do
    star = Star.new(orbit_x: 1_000, orbit_y: 2_000)
    planet = TerrestrialPlanet.new(orbiting: star, orbit_x: 1_300, orbit_y: 2_400)

    assert_in_delta 500, planet.orbit_distance_from_parent_km, 1e-9
  end

  test 'orbit_distance_from_parent_km from the origin when the parent has no position' do
    planet = TerrestrialPlanet.new(orbiting: Star.new, orbit_x: 300, orbit_y: 400)

    assert_in_delta 500, planet.orbit_distance_from_parent_km, 1e-9
  end

  test 'relative_orbit_position is the absolute position less the parent\'s' do
    planet = TerrestrialPlanet.new(orbiting: Star.new(orbit_x: 1_000, orbit_y: 2_000), orbit_x: 1_300, orbit_y: 2_400)

    assert_equal [300.0, 400.0], planet.relative_orbit_position
  end

  test 'relative_orbit_position is nil when the position is unknown' do
    assert_nil TerrestrialPlanet.new(orbiting: Star.new).relative_orbit_position
  end
end
