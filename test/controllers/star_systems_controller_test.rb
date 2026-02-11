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

    assert_redirected_to star_systems_url
  end

  test 'should create empty star_system' do
    generated = '{"gasGiants" => 0, "planetoidBelts" => 0, "terrestrialPlanets" => 0, "sector" => nil, "coordinates" => nil, "remainingOrbits" => [], "name" => "fSDdASDasd", "scanPoints" => 0, "bases" => "", "remarks" => "", "surveyIndex" => 0, "allegiance" => nil, "buildLog" => [], "mainFromDefinition" => nil, "mainWorldType" => nil, "uwp" => nil, "known" => false, "x" => nil, "y" => nil, "totalObjects" => 0, "primaryStar" => {"orbitPosition" => {"x" => 0, "y" => 0}, "inclination" => 0, "eccentricity" => 0, "effectiveHZCODeviation" => 0, "orbit" => 0, "buildLog" => [{"baseline" => "roll: 2, stellarClass IV +1, totalObjects 0 -4"}, {"baselineOrbitNumber" => "baseline orbit, baseline < 1 (-1), minOrbit < 1.0 (0.07), minOrbit 0.07 - baseline/10 (-0.1), roll 7, delta 5/100=0.05, result 0.22000000000000003"}], "fromUWP" => false, "hzcoDeviation" => 0, "stellarClass" => "IV", "stellarType" => "F", "isProtostar" => false, "subtype" => 1, "totalObjects" => 0, "orbitType" => 0, "mass" => 2, "diameter" => 3, "temperature" => 7500, "age" => 2.28, "colour" => "Yellow White", "companion" => nil, "period" => 0, "baseline" => -1, "emptyOrbits" => 2, "spread" => 0.15000000000000002, "availableOrbits" => [[0.07, 20]], "stellarObjects" => [], "occupiedOrbits" => [0.28, 0.41500000000000004], "orbitSequence" => "A", "jump" => 20, "minimumOrbit" => 0.07, "isAnomaly" => false, "isCompanion" => false, "minimumAllowableOrbit" => 0.07, "luminosity" => 25.655605759282196, "totalLuminosity" => 25.655605759282196, "hzco" => 5.943806792559391, "jumpShadow" => 417600000, "totalOrbits" => 20, "au" => 0, "safeJumpTime" => "1m"}, "starCount" => 1, "totalOrbits" => 20, "hasNativeSophont" => false, "hasExtinctSophont" => false, "mainWorld" => nil}'

    stub_request(:post, "http://192.168.1.106:3007/star_system").
      with(
        body: "{\"name\":\"Empty One\",\"counts\":{\"gasGiants\":0,\"planetoidBelts\":0,\"terrestrialPlanets\":0},\"primary\":{\"type\":\"G7\",\"class\":\"V\"}}",
        headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: generated, headers: {})

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
    stub_request(:post, "http://192.168.1.106:3007/star_system").
      with(
        body: "{\"name\":\"Test\",\"counts\":{\"gasGiants\":0,\"planetoidBelts\":0,\"terrestrialPlanets\":0},\"primary\":{\"type\":\"G7\",\"class\":\"V\"}}",
        headers: {
          'Accept'=>'application/json',
          'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
          'Content-Type'=>'application/json',
          'User-Agent'=>'Ruby'
        }).
      to_return(status: 200, body: "", headers: {})

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
