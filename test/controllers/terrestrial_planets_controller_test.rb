require 'test_helper'

class TerrestrialPlanetsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:hierarchy_system)
    @star = @star_system.primary_star
    @params = {
      name: 'Terra Nova', orbit: 3.0, inclination: 1, eccentricity: 0.1, axial_tilt: 20, albedo: 0.3,
      size_code: '8', starport_code: 'C', atmosphere_code: 6, hydrographics_code: 5, population_code: 4,
      government_code: 3, law_level_code: 2, tech_level_code: 7,
      biomass_rating: 0, biocomplexity_rating: 0, biodiversity_rating: 0, compatibility_rating: 0, resource_rating: 7
    }
  end

  test 'should get new with every tab' do
    get new_star_terrestrial_planet_url(@star)

    assert_response :success
    assert_select "button[data-tabs-target='tab']", TerrestrialPlanet.new.edit_sections.size
    assert_select "a[href='#{help_page_path('terrestrial_planet_edit')}']"
  end

  test 'the star page links to the new planet form' do
    get star_url(@star)

    assert_select "a[href='#{new_star_terrestrial_planet_path(@star)}']"
  end

  test 'creates a planet orbiting the star' do
    assert_difference -> { TerrestrialPlanet.count } do
      post star_terrestrial_planets_url(@star), params: { stellar_object: @params }
    end

    planet = TerrestrialPlanet.order(:id).last
    assert_redirected_to stellar_object_url(planet)
    assert_equal @star, planet.orbiting
    assert_equal @star_system.id, planet.star_system_id
    assert planet.orbit_sequence.present?
    distance = Math.hypot(planet.orbit_x - @star.orbit_x.to_f, planet.orbit_y - @star.orbit_y.to_f)
    semi_major_axis = OrbitToAu.convert(3.0) * StellarConstants::AU_TO_KM
    assert_in_delta semi_major_axis, distance, semi_major_axis * 0.2 + 1
  end

  test 'rejects a planet missing any component of the UWP' do
    %i[starport_code atmosphere_code hydrographics_code population_code government_code law_level_code
       tech_level_code].each do |field|
      assert_no_difference -> { TerrestrialPlanet.count }, "expected #{field} to be required" do
        post star_terrestrial_planets_url(@star), params: { stellar_object: @params.merge(field => '') }
      end
    end
  end

  test 'rejects a planet without an orbit' do
    assert_no_difference -> { TerrestrialPlanet.count } do
      post star_terrestrial_planets_url(@star), params: { stellar_object: @params.merge(orbit: '') }
    end

    assert_response :unprocessable_entity
  end
end
