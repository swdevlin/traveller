require 'test_helper'

class PlanetoidsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star = star_systems(:hierarchy_system).primary_star
    @belt = PlanetoidBelt.create!(orbiting: @star, star_system_id: @star.star_system_id, orbit: 5, name: 'Shard')
    @params = { name: 'Rock', orbit: 5.1, inclination: 1, eccentricity: 0.1, size_code: '1', starport_code: 'X', atmosphere_code: 0, hydrographics_code: 0, population_code: 0, government_code: 0, law_level_code: 0, tech_level_code: 0 }
  end

  test 'should get new with every tab' do
    get new_stellar_object_planetoid_url(@belt)

    assert_response :success
    assert_select "button[data-tabs-target='tab']", Planetoid.new.edit_sections.size
  end

  test 'creates a planetoid in the belt' do
    assert_difference -> { Planetoid.count } do
      post stellar_object_planetoids_url(@belt), params: { stellar_object: @params }
    end

    planetoid = Planetoid.order(:id).last
    assert_redirected_to stellar_object_url(@belt)
    assert_equal @star, planetoid.orbiting
    assert_equal @belt.id, planetoid.planetoid_belt_id.to_i
    assert_includes @belt.significant_bodies, planetoid
    assert planetoid.orbit_sequence.present?
    distance = Math.hypot(planetoid.orbit_x - @star.orbit_x.to_f, planetoid.orbit_y - @star.orbit_y.to_f)
    semi_major_axis = OrbitToAu.convert(5.1) * StellarConstants::AU_TO_KM
    assert_in_delta semi_major_axis, distance, semi_major_axis * 0.2 + 1
  end

  test 'rejects a planetoid without a starport' do
    assert_no_difference -> { Planetoid.count } do
      post stellar_object_planetoids_url(@belt), params: { stellar_object: @params.merge(starport_code: '') }
    end

    assert_response :unprocessable_entity
  end

  test 'rejects a planetoid without an atmosphere' do
    assert_no_difference -> { Planetoid.count } do
      post stellar_object_planetoids_url(@belt), params: { stellar_object: @params.merge(atmosphere_code: '') }
    end

    assert_response :unprocessable_entity
  end

  test 'rejects a planetoid missing any component of the UWP' do
    %i[starport_code atmosphere_code hydrographics_code population_code government_code law_level_code
       tech_level_code].each do |field|
      assert_no_difference -> { Planetoid.count }, "expected #{field} to be required" do
        post stellar_object_planetoids_url(@belt), params: { stellar_object: @params.merge(field => '') }
      end
    end
  end

  test 'the belt page lists planetoids with edit and delete actions' do
    post stellar_object_planetoids_url(@belt), params: { stellar_object: @params }
    planetoid = Planetoid.order(:id).last

    get stellar_object_url(@belt)

    assert_response :success
    assert_select "a[href='#{new_stellar_object_planetoid_path(@belt)}']"
    assert_select "a[href='#{edit_stellar_object_path(planetoid)}']"
    assert_select "form[action='#{stellar_object_path(planetoid)}'] button"
  end

  test 'the belt page shows the table even with no planetoids' do
    get stellar_object_url(@belt)

    assert_select "a[href='#{new_stellar_object_planetoid_path(@belt)}']"
    assert_match 'No planetoids recorded.', response.body
  end
end
