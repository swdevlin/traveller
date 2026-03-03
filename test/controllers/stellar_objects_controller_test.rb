require 'test_helper'

class StellarObjectsControllerTest < AuthenticatedIntegrationTest
  setup do
    @parsec = parsecs(:one)
    @star_system = star_systems(:in_one)
    @stellar_object = stellar_objects(:one)
    @gas_giant = gas_giants(:small)
  end

  # test 'should get index' do
  #   get stellar_objects_url
  #   assert_response :success
  # end

  test 'should get new' do
    get new_stellar_object_url
    assert_response :success
  end

  # test 'should create stellar_object' do
  #   assert_difference('StellarObject.count', +1) do
  #     post stellar_objects_url, params: {
  #       stellar_object: {
  #         type: 'GasGiant', # used only to choose class, not permitted
  #         orbiting_star_id: @star.id,
  #         eccentricity: 0,
  #         effective_hzco_deviation: 0.4,
  #         inclination: 0,
  #         orbit: 2.4,
  #         orbit_x: 4,
  #         orbit_y: 3,
  #         name: 'created in test'
  #       }
  #     }
  #   end
  #
  #   so = StellarObject.order(:id).last
  #   assert_redirected_to stellar_object_url(so)
  #   assert_instance_of GasGiant, so
  # end


  # test 'should show stellar_object' do
  #   get stellar_object_url(@stellar_object)
  #   assert_response :success
  # end

  # test 'should get edit' do
  #   get edit_stellar_object_url(@stellar_object)
  #   assert_response :success
  # end

  test 'should update stellar_object' do
    patch stellar_object_url(@stellar_object), params: { stellar_object: { eccentricity: 1, effective_hzco_deviation: 2, inclination: 0.3, orbit: 2, orbit_x: 1, orbit_y: 1 } }
    assert_redirected_to stellar_object_url(@stellar_object)
  end

  test 'should destroy stellar_object' do
    referer_url = subsector_url(subsectors(:subsector_1_1))

    assert_difference('StellarObject.count', -1) do
      delete stellar_object_url(@stellar_object), headers: { 'HTTP_REFERER' => referer_url }
    end

    assert_redirected_to referer_url
  end
end
