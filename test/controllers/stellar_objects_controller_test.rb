require 'test_helper'

class StellarObjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @stellar_object = stellar_objects(:one)
  end

  test 'should get index' do
    get stellar_objects_url
    assert_response :success
  end

  test 'should get new' do
    get new_stellar_object_url
    assert_response :success
  end

  test 'should create stellar_object' do
    assert_difference('StellarObject.count') do
      post stellar_objects_url, params: { stellar_object: { Parsec_id: @stellar_object.Parsec_id, StarSystem_id: @stellar_object.StarSystem_id, eccentricity: @stellar_object.eccentricity, effective_hzco_deviation: @stellar_object.effective_hzco_deviation, inclination: @stellar_object.inclination, orbit: @stellar_object.orbit, orbit_x: @stellar_object.orbit_x, orbit_y: @stellar_object.orbit_y } }
    end

    assert_redirected_to stellar_object_url(StellarObject.last)
  end

  test 'should show stellar_object' do
    get stellar_object_url(@stellar_object)
    assert_response :success
  end

  test 'should get edit' do
    get edit_stellar_object_url(@stellar_object)
    assert_response :success
  end

  test 'should update stellar_object' do
    patch stellar_object_url(@stellar_object), params: { stellar_object: { Parsec_id: @stellar_object.Parsec_id, StarSystem_id: @stellar_object.StarSystem_id, eccentricity: @stellar_object.eccentricity, effective_hzco_deviation: @stellar_object.effective_hzco_deviation, inclination: @stellar_object.inclination, orbit: @stellar_object.orbit, orbit_x: @stellar_object.orbit_x, orbit_y: @stellar_object.orbit_y } }
    assert_redirected_to stellar_object_url(@stellar_object)
  end

  test 'should destroy stellar_object' do
    assert_difference('StellarObject.count', -1) do
      delete stellar_object_url(@stellar_object)
    end

    assert_redirected_to stellar_objects_url
  end
end
