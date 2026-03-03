require 'test_helper'

class GovernmentsControllerTest < AuthenticatedIntegrationTest
  setup do
    @government = governments(:one)
  end

  test 'should get index' do
    get governments_url
    assert_response :success
  end

  test 'should get new' do
    get new_government_url
    assert_response :success
  end

  test 'should create government' do
    assert_difference('Government.count') do
      post governments_url, params: { government: { code: 3, description: @government.description, government_type: @government.government_type } }
    end

    assert_redirected_to government_url(Government.last)
  end

  test 'should show government' do
    get government_url(@government)
    assert_response :success
  end

  test 'should get edit' do
    get edit_government_url(@government)
    assert_response :success
  end

  test 'should update government' do
    patch government_url(@government), params: { government: { code: @government.code, description: @government.description, government_type: @government.government_type } }
    assert_redirected_to government_url(@government)
  end

  test 'should destroy government' do
    assert_difference('Government.count', -1) do
      delete government_url(@government)
    end

    assert_redirected_to governments_url
  end
end
