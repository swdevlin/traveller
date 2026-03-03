require 'test_helper'

class FacilitiesControllerTest < AuthenticatedIntegrationTest
  setup do
    @facility = facilities(:one)
  end

  test 'should get index' do
    get facilities_url
    assert_response :success
  end

  test 'should get new' do
    get new_facility_url
    assert_response :success
  end

  test 'should create facility' do
    assert_difference('Facility.count') do
      post facilities_url, params: { facility: { code: 'NB', name: 'New Base' } }
    end

    assert_redirected_to facility_url(Facility.last)
  end

  test 'should show facility' do
    get facility_url(@facility)
    assert_response :success
  end

  test 'should get edit' do
    get edit_facility_url(@facility)
    assert_response :success
  end

  test 'should update facility' do
    patch facility_url(@facility), params: { facility: { code: @facility.code, name: @facility.name } }
    assert_redirected_to facility_url(@facility)
  end

  test 'should destroy facility' do
    assert_difference('Facility.count', -1) do
      delete facility_url(@facility)
    end

    assert_redirected_to facilities_url
  end
end
