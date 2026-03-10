require 'test_helper'

class StarSystemsControllerTest < AuthenticatedIntegrationTest
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

  test 'should create star_system with random mode' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    assert_difference('StarSystem.count') do
      post subsector_star_systems_url(@subsector), params: { star_system: { name: 'The New One', create_mode: 'random', parsec_id: @parsec.id } }
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

    assert_redirected_to subsector_url(@subsector)
  end

  test 'should create empty star_system' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    assert_difference('StarSystem.count') do
      post subsector_star_systems_url(@subsector), params: {
        star_system: {
          name: 'Empty One',
          parsec_id: @parsec.id,
          create_mode: 'empty',
          primary_spectral_type: 'G',
          primary_spectral_subtype: 7,
          primary_luminosity: 'V'
        }
      }
    end

    star_system = StarSystem.order(:created_at).last
    assert_redirected_to star_system_url(star_system)
  end

  test 'empty mode requires parsec' do
    base = Rails.application.config.x.generator_service

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, body: '', headers: {})

    post subsector_star_systems_url(@subsector), params: {
      star_system: {
        name: 'Test',
        create_mode: 'empty',
        primary_spectral_type: 'G',
        primary_spectral_subtype: 7,
        primary_luminosity: 'V'
      }
    }

    assert_response :unprocessable_entity
  end

  test 'create succeeds with random mode' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    post subsector_star_systems_url(@subsector), params: {
      star_system: {
        name: 'Test',
        parsec_id: @parsec.id,
        create_mode: 'random'
      }
    }

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
  end

  test 'create succeeds with empty mode and primary star params' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    post subsector_star_systems_url(@subsector), params: {
      star_system: {
        name: 'Test',
        parsec_id: @parsec.id,
        create_mode: 'empty',
        primary_spectral_type: 'G',
        primary_spectral_subtype: '2',
        primary_luminosity: 'V'
      }
    }

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
  end
end
