require 'test_helper'

class StarTest < ActiveSupport::TestCase
  # primary_star tests

  test 'primary_star returns self when not orbiting anything' do
    primary = stellar_objects(:primary_for_hierarchy)
    assert_equal primary, primary.primary_star
  end

  test 'primary_star returns the primary when orbiting another star' do
    secondary = stellar_objects(:secondary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    assert_equal primary, secondary.primary_star
  end

  test 'primary_star returns the primary through multiple levels' do
    tertiary = stellar_objects(:tertiary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    assert_equal primary, tertiary.primary_star
  end

  # ancestor_stars tests

  test 'ancestor_stars returns empty array for primary star' do
    primary = stellar_objects(:primary_for_hierarchy)
    assert_empty primary.ancestor_stars
  end

  test 'ancestor_stars returns parent for secondary star' do
    secondary = stellar_objects(:secondary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    ancestors = secondary.ancestor_stars
    assert_equal 1, ancestors.length
    assert_equal primary, ancestors.first
  end

  test 'ancestor_stars returns chain for tertiary star' do
    tertiary = stellar_objects(:tertiary_star)
    secondary = stellar_objects(:secondary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    ancestors = tertiary.ancestor_stars
    assert_equal 2, ancestors.length
    assert_equal secondary, ancestors[0]
    assert_equal primary, ancestors[1]
  end

  # distance_from_primary_km tests

  test 'distance_from_primary_km returns 0 for primary star' do
    primary = stellar_objects(:primary_for_hierarchy)
    assert_equal 0.0, primary.distance_from_primary_km
  end

  test 'distance_from_primary_km returns AU distance in km for secondary' do
    secondary = stellar_objects(:secondary_star)
    # Secondary is at 10 AU from primary
    expected_km = 10.0 * StellarConstants::AU_TO_KM

    assert_in_delta expected_km, secondary.distance_from_primary_km, 1.0
  end

  test 'distance_from_primary_km sums distances for tertiary' do
    tertiary = stellar_objects(:tertiary_star)
    # Tertiary is at 0.5 AU from secondary, which is at 10 AU from primary
    # Total = 10.5 AU
    expected_km = 10.5 * StellarConstants::AU_TO_KM

    assert_in_delta expected_km, tertiary.distance_from_primary_km, 1.0
  end

  # mapped_bodies tests

  test 'mapped_bodies excludes Planetoids' do
    star_system = StarSystem.create!(name: 'Test', parsec: parsecs(:one))
    star = Star.create!(
      name: 'Primary', star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    planetoid = Planetoid.create!(orbiting: star, size_code: '5')
    gas_giant = GasGiant.create!(orbiting: star)

    assert_includes star.mapped_bodies, gas_giant
    assert_not_includes star.mapped_bodies, planetoid
  end

  # reassign_orbit_sequences_after_destroy tests

  test 'deleting a star with direct star_system reassigns orbit sequences' do
    star = stellar_objects(:secondary_star)
    primary = stellar_objects(:primary_for_hierarchy)

    star.destroy!

    assert_equal 'A', primary.reload.orbit_sequence
  end

  test 'deleting a companion star without direct star_system reassigns orbit sequences' do
    # companion_no_system has orbiting: primary_for_hierarchy but no star_system association.
    # Without the fix, orbit_star_system_for_destroy returned nil and no reassignment happened.
    star = stellar_objects(:companion_no_system)
    primary = stellar_objects(:primary_for_hierarchy)

    star.destroy!

    assert_equal 'A', primary.reload.orbit_sequence
  end
end
