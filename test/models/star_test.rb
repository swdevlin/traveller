require 'test_helper'

class StarTest < ActiveSupport::TestCase
  # primary_star tests

  test 'primary_star returns self when not orbiting anything' do
    primary = stars(:primary_for_hierarchy)
    assert_equal primary, primary.primary_star
  end

  test 'primary_star returns the primary when orbiting another star' do
    secondary = stars(:secondary_star)
    primary = stars(:primary_for_hierarchy)

    assert_equal primary, secondary.primary_star
  end

  test 'primary_star returns the primary through multiple levels' do
    tertiary = stars(:tertiary_star)
    primary = stars(:primary_for_hierarchy)

    assert_equal primary, tertiary.primary_star
  end

  # ancestor_stars tests

  test 'ancestor_stars returns empty array for primary star' do
    primary = stars(:primary_for_hierarchy)
    assert_empty primary.ancestor_stars
  end

  test 'ancestor_stars returns parent for secondary star' do
    secondary = stars(:secondary_star)
    primary = stars(:primary_for_hierarchy)

    ancestors = secondary.ancestor_stars
    assert_equal 1, ancestors.length
    assert_equal primary, ancestors.first
  end

  test 'ancestor_stars returns chain for tertiary star' do
    tertiary = stars(:tertiary_star)
    secondary = stars(:secondary_star)
    primary = stars(:primary_for_hierarchy)

    ancestors = tertiary.ancestor_stars
    assert_equal 2, ancestors.length
    assert_equal secondary, ancestors[0]
    assert_equal primary, ancestors[1]
  end

  # distance_from_primary_km tests

  test 'distance_from_primary_km returns 0 for primary star' do
    primary = stars(:primary_for_hierarchy)
    assert_equal 0.0, primary.distance_from_primary_km
  end

  test 'distance_from_primary_km returns AU distance in km for secondary' do
    secondary = stars(:secondary_star)
    # Secondary is at 10 AU from primary
    expected_km = 10.0 * StellarConstants::AU_TO_KM

    assert_in_delta expected_km, secondary.distance_from_primary_km, 1.0
  end

  test 'distance_from_primary_km sums distances for tertiary' do
    tertiary = stars(:tertiary_star)
    # Tertiary is at 0.5 AU from secondary, which is at 10 AU from primary
    # Total = 10.5 AU
    expected_km = 10.5 * StellarConstants::AU_TO_KM

    assert_in_delta expected_km, tertiary.distance_from_primary_km, 1.0
  end
end
