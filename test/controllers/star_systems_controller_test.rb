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

  test 'show page labels the player notes Survey Records and shows Classified Records to the referee' do
    @star_system.update!(player_notes: 'Seen by all', referee_notes: 'Referee eyes only')

    get star_system_url(@star_system)

    assert_response :success
    assert_select 'div', text: /Survey Records/
    assert_select 'div', text: /Classified Records/
    assert_includes response.body, 'Seen by all'
    assert_includes response.body, 'Referee eyes only'
  end

  test 'should save survey and classified records' do
    patch star_system_url(@star_system), params: { star_system: { player_notes: 'Survey text', referee_notes: 'Classified text' } }

    assert_equal 'Survey text', @star_system.reload.player_notes
    assert_equal 'Classified text', @star_system.referee_notes
  end

  test 'should get webp map' do
    get map_star_system_url(@star_system, format: :webp)
    assert_response :success
  end

  test 'main world details show the major cities table' do
    planet = stellar_objects(:two)
    planet.update_column(:star_system_id, @star_system.id)
    @star_system.update_column(:main_world_id, planet.id)

    get star_system_url(@star_system)

    assert_response :success
    assert_select 'turbo-frame#cities-table' do
      assert_select 'td', text: 'Newhaven'
    end
  end

  test 'should get edit' do
    get edit_star_system_url(@star_system)
    assert_response :success
  end

  test 'edit is forbidden for a logged-in user who does not referee this campaign' do
    sign_out
    sign_in_as users(:two)
    get edit_star_system_url(@star_system)
    assert_response :forbidden
  end

  test 'map is reachable for a logged-in user who does not referee this campaign, at the player variant' do
    get map_star_system_url(@star_system, format: :svg)
    owner_etag = response.headers['ETag']

    sign_out
    sign_in_as users(:two)
    get map_star_system_url(@star_system, format: :svg)

    assert_response :success
    refute_equal owner_etag, response.headers['ETag']
  end

  test 'should update star_system' do
    patch star_system_url(@star_system), params: { star_system: { name: @star_system.name } }
    assert_redirected_to star_system_url(@star_system)
  end

  test 'moves a star system to an empty hex' do
    target = parsecs(:four)
    patch move_star_system_url(@star_system), params: { sector_id: target.sector_id, hex_code: target.hex_code }

    assert_redirected_to star_system_url(@star_system)
    assert_equal target, @star_system.reload.parsec
  end

  test 'moves a star system to a hex picked from the grid' do
    target = parsecs(:four)
    patch move_star_system_url(@star_system), params: { parsec_id: target.id }

    assert_equal target, @star_system.reload.parsec
  end

  test 'move modal renders a map with click targets, excluding the current and occupied hexes' do
    get move_modal_star_system_url(@star_system, return_to: subsector_path(@subsector))

    assert_response :success
    assert_select 'a[data-hex-move]' do |anchors|
      hrefs = anchors.map { |a| a['href'] }
      assert(hrefs.any? { |h| h.include?("parsec_id=#{parsecs(:four).id}") })
      assert(hrefs.none? { |h| h.include?("parsec_id=#{@parsec.id}&") || h.include?("parsec_id=#{star_systems(:in_two).parsec_id}&") })
    end
    assert_select 'input[name=return_to][value=?]', subsector_path(@subsector)
  end

  test 'moves a star system into another sector and returns to the page it came from' do
    target = Parsec.create!(sector: sectors(:two), x: 34, y: 79, q: 34, r: 63, s: -97)
    patch move_star_system_url(@star_system),
          params: { sector_id: target.sector_id, hex_code: target.hex_code, return_to: subsector_path(@subsector) }

    assert_redirected_to subsector_path(@subsector)
    assert_equal target, @star_system.reload.parsec
  end

  test 'ignores a return_to that is not a local path' do
    target = parsecs(:four)
    patch move_star_system_url(@star_system),
          params: { sector_id: target.sector_id, hex_code: target.hex_code, return_to: '//evil.example' }

    assert_redirected_to star_system_url(@star_system)
  end

  test 'refuses to move a star system into an occupied hex' do
    occupied = star_systems(:in_two).parsec
    patch move_star_system_url(@star_system), params: { sector_id: occupied.sector_id, hex_code: occupied.hex_code }

    assert_equal @parsec, @star_system.reload.parsec
    assert_match(/already contains a star system/, flash[:alert])
  end

  test 'refuses to move a star system to an invalid or missing hex' do
    patch move_star_system_url(@star_system), params: { sector_id: @parsec.sector_id, hex_code: 'abc' }
    assert_equal @parsec, @star_system.reload.parsec
    assert flash[:alert].present?

    patch move_star_system_url(@star_system), params: { sector_id: @parsec.sector_id, hex_code: '9999' }
    assert_equal @parsec, @star_system.reload.parsec
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

  test 'build configuration create keeps the entered build text when invalid' do
    build = 'name: [unclosed'

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: build }
    }

    assert_response :unprocessable_entity
    assert_select 'textarea', text: build
  end

  test 'build configuration create adds rogues and strips them from the generator payload' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    posted = nil
    stub_request(:post, "#{base}/star_system")
      .with { |req| posted = JSON.parse(req.body) }
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    build = <<~YAML
      name: Halvor
      rogues:
        - type: relic
          name: The Monolith
    YAML

    assert_difference -> { @parsec.rogues.where(type: 'Relic').count } do
      post subsector_star_systems_url(@subsector), params: {
        star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: build }
      }
    end

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
    assert_not posted.key?('rogues')
    assert_equal 'The Monolith', @parsec.rogues.where(type: 'Relic').sole.name
  end

  test 'build configuration create uses config bases over generator response bases' do
    base = Rails.application.config.x.generator_service
    body = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('bases' => [facilities(:one).code]).to_json

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    build = <<~YAML
      name: Halvor
      bases:
        - #{facilities(:two).code}
    YAML

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: build }
    }

    star_system = StarSystem.order(:created_at).last
    assert_redirected_to star_system_url(star_system)
    assert_equal [facilities(:two).code], star_system.facilities.pluck(:code)
  end

  test 'build configuration create converts governmentTypes comma list to an integer array' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    posted = nil
    stub_request(:post, "#{base}/star_system")
      .with { |req| posted = JSON.parse(req.body) }
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    build = <<~YAML
      name: Halvor
      populated:
        type: full
        governmentTypes: 1,2,A
    YAML

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: build }
    }

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
    assert_equal [1, 2, 10], posted['populated']['governmentTypes']
  end

  test 'build configuration create defaults limitedMainWorldEccentricity from the campaign setting' do
    campaigns(:one).update!(campaign_type: 'charted_space')
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    posted = nil
    stub_request(:post, "#{base}/star_system")
      .with { |req| posted = JSON.parse(req.body) }
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: 'name: Halvor' }
    }

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
    assert_equal false, posted['limitedMainWorldEccentricity']
  end

  test 'build configuration create does not overwrite an explicit limitedMainWorldEccentricity' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    posted = nil
    stub_request(:post, "#{base}/star_system")
      .with { |req| posted = JSON.parse(req.body) }
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    build = <<~YAML
      name: Halvor
      limitedMainWorldEccentricity: false
    YAML

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: build }
    }

    assert_redirected_to star_system_url(StarSystem.order(:created_at).last)
    assert_equal false, posted['limitedMainWorldEccentricity']
  end

  test 'build configuration create falls back to generator response bases when config has none' do
    base = Rails.application.config.x.generator_service
    body = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('bases' => [facilities(:one).code]).to_json

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    post subsector_star_systems_url(@subsector), params: {
      star_system: { parsec_id: @parsec.id, create_mode: 'build_configuration', build: 'name: Halvor' }
    }

    star_system = StarSystem.order(:created_at).last
    assert_redirected_to star_system_url(star_system)
    assert_equal [facilities(:one).code], star_system.facilities.pluck(:code)
  end

  test 'replace with a rogues entry replaces the existing rogues in the hex' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    existing = stellar_objects(:one)

    build = <<~YAML
      rogues:
        - type: relic
    YAML

    post do_replace_star_system_url(@star_system), params: {
      star_system: { create_mode: 'build_configuration', build: build }
    }

    assert_redirected_to star_system_url(@star_system)
    assert_not StellarObject.exists?(existing.id)
    assert_equal %w[Relic], @parsec.rogues.pluck(:type)
  end

  test 'replace without a rogues entry leaves existing rogues alone' do
    base = Rails.application.config.x.generator_service
    body = file_fixture('star_system_import_minimal.json').read

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    existing = stellar_objects(:one)

    post do_replace_star_system_url(@star_system), params: {
      star_system: { create_mode: 'build_configuration', build: 'name: Halvor' }
    }

    assert_redirected_to star_system_url(@star_system)
    assert StellarObject.exists?(existing.id)
  end

  test 'replace with config bases replaces existing facilities' do
    base = Rails.application.config.x.generator_service
    body = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('bases' => [facilities(:one).code]).to_json

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    StarSystemFacility.create!(star_system: @star_system, facility: facilities(:one))

    build = <<~YAML
      name: Halvor
      bases:
        - #{facilities(:two).code}
    YAML

    post do_replace_star_system_url(@star_system), params: {
      star_system: { create_mode: 'build_configuration', build: build }
    }

    assert_redirected_to star_system_url(@star_system)
    assert_equal [facilities(:two).code], @star_system.reload.facilities.pluck(:code)
  end

  test 'replace without config bases falls back to generator response bases' do
    base = Rails.application.config.x.generator_service
    body = JSON.parse(file_fixture('star_system_import_minimal.json').read)
      .merge('bases' => [facilities(:one).code]).to_json

    stub_request(:post, "#{base}/star_system")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: body)

    post do_replace_star_system_url(@star_system), params: {
      star_system: { create_mode: 'build_configuration', build: 'name: Halvor' }
    }

    assert_redirected_to star_system_url(@star_system)
    assert_equal [facilities(:one).code], @star_system.reload.facilities.pluck(:code)
  end

  test 'update_trade_codes updates the main world trade codes, not the star system' do
    planet = stellar_objects(:two)
    planet.update_column(:star_system_id, @star_system.id)
    @star_system.update_column(:main_world_id, planet.id)

    post update_trade_codes_star_system_url(@star_system),
      params: { trade_code_ids: [trade_codes(:tc1).id, trade_codes(:tc2).id] }

    assert_redirected_to star_system_url(@star_system)
    assert_equal [trade_codes(:tc1), trade_codes(:tc2)], planet.reload.trade_codes.order(:code).to_a
    assert_equal [trade_codes(:tc1), trade_codes(:tc2)], @star_system.reload.trade_codes.order(:code).to_a
  end

  test 'edit_trade_codes redirects with an alert when the star system has no main world' do
    @star_system.update_column(:main_world_id, nil)

    get edit_trade_codes_star_system_url(@star_system)

    assert_redirected_to star_system_url(@star_system)
    assert_equal 'Select a main world before editing trade codes.', flash[:alert]
  end

  test 'update_trade_codes redirects with an alert when the star system has no main world' do
    @star_system.update_column(:main_world_id, nil)

    post update_trade_codes_star_system_url(@star_system), params: { trade_code_ids: [trade_codes(:tc1).id] }

    assert_redirected_to star_system_url(@star_system)
    assert_equal 'Select a main world before editing trade codes.', flash[:alert]
  end

  test 'generate_maps queues a job for each mappable body without a map' do
    planet = stellar_objects(:planet_near_primary)
    planet.update!(size_code: '5', atmosphere_code: 5, hydrographics_code: 5, orbit: 3.0)
    system = StarSystem.find(planet.star_system_id)
    expected = system.mappable_bodies_without_map.pluck(:id)
    assert_includes expected, planet.id

    assert_enqueued_jobs expected.size, only: GeneratePlanetMapJob do
      post generate_maps_star_system_url(system)
    end
    assert_redirected_to star_system_url(system)
  end

  test 'generate_maps skips bodies that already have a map' do
    planet = stellar_objects(:planet_near_primary)
    planet.update!(size_code: '5', atmosphere_code: 5, hydrographics_code: 5, orbit: 3.0)
    planet.store_map('<svg xmlns="http://www.w3.org/2000/svg" width="10" height="10"><rect width="5" height="5"/></svg>')
    system = StarSystem.find(planet.star_system_id)

    assert_not_includes system.mappable_bodies_without_map.pluck(:id), planet.id
    post generate_maps_star_system_url(system)
    assert_not(enqueued_jobs.any? { it['arguments'].first == planet.id })
  end

  test 'show has a disabled generate maps item when there is nothing to map' do
    StellarObject.where(star_system_id: @star_system.id).where.not(type: 'Star').find_each do |body|
      body.update_columns(size_code: 'S') if body.respond_to?(:map_supported?)
    end

    get star_system_url(@star_system)

    assert_response :success
    assert_select 'button[disabled][title*="already have maps"]', text: /Generate maps/
    assert_select 'button', text: /Delete/
  end
end
