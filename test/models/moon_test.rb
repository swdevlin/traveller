require 'test_helper'

class MoonTest < ActiveSupport::TestCase
  # effective_jump_shadow_km

  test 'effective_jump_shadow_km returns own shadow when not orbiting anything' do
    moon = Moon.new(diameter: 1737, size_code: '2', data: {})
    assert_equal 173_700, moon.effective_jump_shadow_km
  end

  test 'effective_jump_shadow_km accounts for moon-planet distance in planet shadow' do
    moon = stellar_objects(:moon_inside_planet_shadow)
    planet = stellar_objects(:planet_near_primary)

    moon_to_planet_km = moon.orbit * planet.diameter
    expected = planet.jump_shadow - moon_to_planet_km

    assert_in_delta expected, moon.effective_jump_shadow_km, 1.0
  end

  test 'effective_jump_shadow_km returns own shadow when outside all parent shadows' do
    moon = stellar_objects(:moon_outside_all_shadows)
    assert_equal moon.jump_shadow, moon.effective_jump_shadow_km
  end

  test 'effective_jump_shadow_km accounts for star shadow via cumulative distance' do
    moon = stellar_objects(:moon_orbiting_secondary_planet)
    planet = stellar_objects(:planet_orbiting_secondary)
    secondary = stellar_objects(:secondary_star)

    moon_to_planet_km = moon.orbit * planet.diameter
    cumulative = moon_to_planet_km + planet.au * StellarConstants::AU_TO_KM
    expected = secondary.jump_shadow - cumulative

    assert_in_delta expected, moon.effective_jump_shadow_km, 1.0
  end

  # effective_jump_shadow_source

  test 'effective_jump_shadow_source is nil when own shadow dominates' do
    moon = stellar_objects(:moon_outside_all_shadows)
    assert_nil moon.effective_jump_shadow_source
  end

  test 'effective_jump_shadow_source is the planet when planet shadow dominates' do
    moon = stellar_objects(:moon_inside_planet_shadow)
    planet = stellar_objects(:planet_near_primary)
    assert_equal planet, moon.effective_jump_shadow_source
  end

  test 'effective_jump_shadow_source is the star when star shadow dominates' do
    moon = stellar_objects(:moon_orbiting_secondary_planet)
    secondary = stellar_objects(:secondary_star)
    assert_equal secondary, moon.effective_jump_shadow_source
  end

  test 'effective_jump_shadow_source returns nil for unsaved moon with no orbiting' do
    moon = Moon.new(diameter: 500, size_code: '1', data: {})
    assert_nil moon.effective_jump_shadow_source
  end
end
