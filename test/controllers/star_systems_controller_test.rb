require 'test_helper'

class StarSystemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @star_system = star_systems(:in_one)
    @parsec = parsecs(:one)
    @subsector = subsectors(:subsector_1_1)
  end

  test 'should get index' do
    get subsector_star_systems_url(@subsector)
    assert_response :success
  end

  test 'should get new' do
    get new_star_system_url
    assert_response :success
  end

  test 'should create star_system' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    assert_difference('StarSystem.count') do
      post subsector_star_systems_url(@subsector), params: { star_system: { name: 'The New One', random: '1', parsec_id: @parsec.id } }
    end

    star_system = StarSystem.order(:created_at).last
    assert_redirected_to star_system_url(star_system)
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
    patch star_system_url(@star_system), params: { star_system: { name: @star_system.name } }
    assert_redirected_to star_system_url(@star_system)
  end

  test 'should destroy star_system' do
    assert_difference('StarSystem.count', -1) do
      delete star_system_url(@star_system)
    end

    assert_redirected_to star_systems_url
  end
end
