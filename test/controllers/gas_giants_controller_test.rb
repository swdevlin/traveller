require 'test_helper'

class GasGiantsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star_system = star_systems(:hierarchy_system)
    @star = @star_system.primary_star
    @params = {
      name: 'Jove', orbit: 6.0, inclination: 1.5, eccentricity: 0.05, diameter: 120_000, mass: 0.002,
      data: { code: 'GL', period: 11.8, axial_tilt: 3.1 }
    }
  end

  test 'should get new' do
    get new_star_gas_giant_url(@star)

    assert_response :success
    %w[orbit inclination eccentricity diameter].each do |field|
      assert_select "[name='stellar_object[#{field}]']", 1, "expected a #{field} field"
    end
    %w[code period axial_tilt].each do |field|
      assert_select "[name='stellar_object[data][#{field}]']", 1, "expected a #{field} field"
    end
  end

  test 'creates a gas giant orbiting the star with every field the starmap needs' do
    assert_difference -> { GasGiant.count } do
      post star_gas_giants_url(@star), params: { stellar_object: @params }
    end

    gas_giant = GasGiant.order(:id).last
    assert_redirected_to stellar_object_url(gas_giant)
    assert_equal @star, gas_giant.orbiting
    assert_equal @star_system.id, gas_giant.star_system_id
    assert_equal 'GL', gas_giant.code
    assert_equal 11.8, gas_giant.period
    assert_equal 3.1, gas_giant.axial_tilt
    assert_equal 120_000.0, gas_giant.diameter
    assert gas_giant.orbit_sequence.present?
  end

  test 'the orbital position is calculated from the orbit' do
    post star_gas_giants_url(@star), params: { stellar_object: @params }

    gas_giant = GasGiant.order(:id).last
    distance = Math.hypot(gas_giant.orbit_x - @star.orbit_x.to_f, gas_giant.orbit_y - @star.orbit_y.to_f)
    semi_major_axis = OrbitToAu.convert(6.0) * StellarConstants::AU_TO_KM
    assert_in_delta semi_major_axis, distance, semi_major_axis * 0.05 + 1
  end

  test 'rejects a gas giant missing required fields' do
    assert_no_difference -> { GasGiant.count } do
      post star_gas_giants_url(@star), params: { stellar_object: @params.merge(orbit: '', data: { code: '', period: '', rotation: '', axial_tilt: '' }) }
    end

    assert_response :unprocessable_entity
  end
end
