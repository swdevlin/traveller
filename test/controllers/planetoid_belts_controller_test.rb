require 'test_helper'

class PlanetoidBeltsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:hierarchy_system)
    @star = @star_system.primary_star
    @params = {
      name: 'Shard', orbit: 6.0, inclination: 1.5, eccentricity: 0.05,
      data: { period: 1500, m_type: 20, s_type: 40, c_type: 30, o_type: 10, resource_rating: 7, bulk: 3, span: 0.5 }
    }
  end

  test 'should get new' do
    get new_star_planetoid_belt_url(@star)

    assert_response :success
    assert_select "button[data-tabs-target='tab']", PlanetoidBelt.new.edit_sections.size
    assert_select "[data-tabs-target='panel']", PlanetoidBelt.new.edit_sections.size
    %w[orbit inclination eccentricity starport_code atmosphere_code hydrographics_code population_code government_code
       law_level_code tech_level_code].each do |field|
      assert_select "[name='stellar_object[#{field}]']", 1, "expected a #{field} field"
    end
    %w[period m_type s_type c_type o_type resource_rating bulk span].each do |field|
      assert_select "[name='stellar_object[data][#{field}]']", 1, "expected a #{field} field"
    end
  end

  test 'creates a planetoid belt orbiting the star with every field the starmap needs' do
    assert_difference -> { PlanetoidBelt.count } do
      post star_planetoid_belts_url(@star), params: { stellar_object: @params }
    end

    belt = PlanetoidBelt.order(:id).last
    assert_redirected_to stellar_object_url(belt)
    assert_equal @star, belt.orbiting
    assert_equal @star_system.id, belt.star_system_id
    assert_equal 1500.0, belt.period
    assert_equal 40, belt.s_type
    assert belt.orbit_sequence.present?
  end

  test 'the orbital position is calculated from the orbit' do
    post star_planetoid_belts_url(@star), params: { stellar_object: @params }

    belt = PlanetoidBelt.order(:id).last
    distance = Math.hypot(belt.orbit_x - @star.orbit_x.to_f, belt.orbit_y - @star.orbit_y.to_f)
    semi_major_axis = OrbitToAu.convert(6.0) * StellarConstants::AU_TO_KM
    assert_in_delta semi_major_axis, distance, semi_major_axis * 0.05 + 1
  end

  test 'rejects a belt missing required fields' do
    assert_no_difference -> { PlanetoidBelt.count } do
      post star_planetoid_belts_url(@star), params: { stellar_object: @params.merge(orbit: '', data: { period: '' }) }
    end

    assert_response :unprocessable_entity
  end

  test 'rejects a composition that does not total 100' do
    assert_no_difference -> { PlanetoidBelt.count } do
      post star_planetoid_belts_url(@star), params: { stellar_object: @params.merge(data: @params[:data].merge(o_type: 50)) }
    end

    assert_response :unprocessable_entity
  end
end
