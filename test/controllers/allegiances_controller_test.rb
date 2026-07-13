require 'test_helper'

class AllegiancesControllerTest < AuthenticatedIntegrationTest
  setup do
    @allegiance = allegiances(:one)
  end

  test 'should get index' do
    get allegiances_url
    assert_response :success
  end

  test 'should get new' do
    get new_allegiance_url
    assert_response :success
  end

  test 'should create allegiance' do
    assert_difference('Allegiance.count') do
      post allegiances_url, params: { allegiance: { code: '1243N', name: 'A new one' } }
    end

    assert_redirected_to allegiance_url(Allegiance.last)
  end

  test 'should show allegiance' do
    get allegiance_url(@allegiance)
    assert_response :success
  end

  test 'should get edit' do
    get edit_allegiance_url(@allegiance)
    assert_response :success
  end

  test 'should update allegiance' do
    patch allegiance_url(@allegiance), params: { allegiance: { code: @allegiance.code, name: @allegiance.name } }
    assert_redirected_to allegiance_url(@allegiance)
  end

  test 'toggle_known flips the known flag and redirects back to the index' do
    assert @allegiance.known?

    patch toggle_known_allegiance_url(@allegiance)

    assert_redirected_to allegiances_url
    assert_not @allegiance.reload.known?

    patch toggle_known_allegiance_url(@allegiance)

    assert @allegiance.reload.known?
  end

  test 'should destroy allegiance' do
    assert_difference('Allegiance.count', -1) do
      delete allegiance_url(@allegiance)
    end

    assert_redirected_to allegiances_url
  end
end
