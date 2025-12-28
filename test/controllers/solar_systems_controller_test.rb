require 'test_helper'

class StarSystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @star_system = star_systems(:one)
    @parsec = parsecs(:one)
  end

  test 'should get index' do
    get star_systems_url
    assert_response :success
  end

  test 'should get new' do
    get new_star_system_url
    assert_response :success
  end

  test 'should create star_system' do
    assert_difference('StarSystem.count') do
      post star_systems_url, params: { star_system: { name: 'new system', parsec_id: @parsec.id } }
    end

    assert_redirected_to star_system_url(StarSystem.last)
  end

  test 'should show star_system' do
    get star_system_url(@star_system)
    assert_response :success
  end

  test 'should get edit' do
    get edit_star_system_url(@star_system)
    assert_response :success
  end

  test 'should update star_system' do
    patch star_system_url(@star_system), params: { star_system: { meta: @star_system.meta, name: @star_system.name, parses_id: @star_system.parsec_id } }
    assert_redirected_to star_system_url(@star_system)
  end

  test 'should destroy star_system' do
    assert_difference('StarSystem.count', -1) do
      delete star_system_url(@star_system)
    end

    assert_redirected_to star_systems_url
  end
end
