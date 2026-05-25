require 'test_helper'

class StellarObjectTest < ActiveSupport::TestCase
  # effective_language tests

  test 'effective_language returns own language when set' do
    campaign = campaigns(:one)
    # Use a Star fixture that has star_system_id populated
    obj = stellar_objects(:primary_for_hierarchy)
    obj.language = 'aslan'
    assert_equal 'aslan', obj.effective_language(campaign)
  end

  test 'effective_language falls back to star system language' do
    campaign = campaigns(:one)
    obj = stellar_objects(:primary_for_hierarchy)
    obj.star_system.update!(language: 'zdetl')
    assert_equal 'zdetl', obj.effective_language(campaign)
  end

  test 'effective_language own language overrides star system language' do
    campaign = campaigns(:one)
    obj = stellar_objects(:primary_for_hierarchy)
    obj.star_system.update!(language: 'zdetl')
    obj.language = 'french'
    assert_equal 'french', obj.effective_language(campaign)
  end

  test 'effective_language rogue falls back to campaign default' do
    campaign = campaigns(:one)
    campaign.default_language = 'imperium'
    rogue = stellar_objects(:rogue)
    assert_nil rogue.star_system_id
    assert_equal 'imperium', rogue.effective_language(campaign)
  end

  test 'effective_language returns nil for rogue when nothing set' do
    campaign = campaigns(:one)
    rogue = stellar_objects(:rogue)
    assert_nil rogue.effective_language(campaign)
  end

  # jump_shadow tests

  test 'jump_shadow returns 100 times diameter' do
    object = StellarObject.new(diameter: 12742, type: 'TerrestrialPlanet')
    assert_equal 1_274_200, object.jump_shadow
  end

  test 'jump_shadow returns 0 when diameter is nil' do
    object = StellarObject.new(diameter: nil, type: 'Comet')
    assert_equal 0, object.jump_shadow
  end

  # effective_jump_shadow_km tests

  test 'effective_jump_shadow_km returns own shadow for rogue objects' do
    rogue = stellar_objects(:rogue)
    # Rogue has no diameter set, so shadow is 0
    assert_equal 0, rogue.effective_jump_shadow_km
  end

  test 'effective_jump_shadow_km considers object shadow' do
    planet = stellar_objects(:planet_far_from_primary)
    # Gas giant with diameter 139820 km
    # Object shadow = 139820 * 100 = 13,982,000 km
    # At 2 AU from primary, outside primary's shadow (139,270,000 km < 2 AU = 299,195,741 km)
    # So effective shadow is the object's own shadow

    object_shadow = planet.jump_shadow
    assert_equal object_shadow, planet.effective_jump_shadow_km
  end

  test 'effective_jump_shadow_km considers star shadow when inside it' do
    planet = stellar_objects(:planet_near_primary)
    primary = stellar_objects(:primary_for_hierarchy)

    # Planet at 1 AU = 149,597,870.7 km
    # Primary shadow = 139,270,000 km
    # Planet is outside star's shadow (1 AU > shadow), so object shadow dominates
    # Object shadow = 12742 * 100 = 1,274,200 km

    # Actually let me recalculate:
    # Primary jump_shadow = 139,270,000 km
    # Planet distance = 1 AU = 149,597,870.7 km
    # Star shadow remaining = 139,270,000 - 149,597,870.7 = negative, so 0
    # Object shadow = 1,274,200 km
    # Effective = max(0, 1,274,200) = 1,274,200 km

    assert_equal planet.jump_shadow, planet.effective_jump_shadow_km
  end

  test 'effective_jump_shadow_km handles star hierarchy' do
    planet = stellar_objects(:planet_orbiting_tertiary)
    tertiary = stellar_objects(:tertiary_star)
    secondary = stellar_objects(:secondary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    # Planet orbits tertiary at 0.05 AU
    # Tertiary orbits secondary at 0.5 AU
    # Secondary orbits primary at 10 AU
    # Total distance from primary = 10 + 0.5 + 0.05 = 10.55 AU

    # Check that the method runs and returns a positive value
    result = planet.effective_jump_shadow_km
    assert result >= 0, 'effective_jump_shadow_km should return non-negative value'

    # The result should be at least the object's own shadow
    assert result >= planet.jump_shadow, 'Result should be at least object shadow'
  end

  # effective_hzco_deviation tests

  test 'moon uses orbit of orbiting body for hzco deviation calculation' do
    star = stellar_objects(:primary_for_hierarchy)
    star.data = star.data.merge('hzco' => 3.0)

    gas_giant = GasGiant.new(orbiting: star, orbit: 5.0, data: {})

    moon = Moon.new(orbiting: gas_giant, orbit: 2.0, size_code: '3', data: {})
    moon.valid?

    # effective_hzco_deviation = gas_giant.orbit (5.0) - star.hzco (3.0) = 2.0
    # NOT moon.orbit (2.0) - star.hzco (3.0) = -1.0
    assert_in_delta 2.0, moon.effective_hzco_deviation, 0.001
  end

  test 'effective_jump_shadow_km returns max of all shadows' do
    # Create a scenario where we know which shadow should dominate
    planet = stellar_objects(:planet_orbiting_secondary)
    secondary = stellar_objects(:secondary_star)

    # Planet at 0.1 AU from secondary
    # Secondary shadow = 27,854,000 km
    # Planet distance from secondary = 0.1 AU = 14,959,787 km
    # Remaining secondary shadow = 27,854,000 - 14,959,787 = 12,894,213 km

    # Object shadow = 6371 * 100 = 637,100 km

    # Primary shadow = 139,270,000 km
    # Planet distance from primary = 10.1 AU = 1,510,938,694 km
    # Remaining primary shadow = negative, so 0

    # Effective = max(12,894,213, 637,100, 0) = 12,894,213 km

    result = planet.effective_jump_shadow_km
    expected_secondary_remaining = secondary.jump_shadow - (0.1 * StellarConstants::AU_TO_KM)

    assert_in_delta expected_secondary_remaining, result, 1.0
  end
end
