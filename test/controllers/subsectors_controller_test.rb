require 'test_helper'

class SubsectorsControllerTest < AuthenticatedIntegrationTest
  setup do
    @subsector = subsectors(:subsector_1_1)
    @sector = sectors(:one)
  end

  test 'should get index' do
    get subsectors_url
    assert_response :success
  end

  test 'should show subsector' do
    get subsector_url(@subsector)
    assert_response :success
  end

  test 'map colours a sector capital system name when the campaign colour is set' do
    campaigns(:one).update!(sector_capital_colour: '#ff0000')

    ul, = @subsector.universal_coordinates
    parsec = Parsec.create!(sector: @sector, x: ul.x + 3, y: ul.y - 3)
    star_system = StarSystem.create!(name: 'Capitalis', parsec: parsec)
    star = Star.create!(
      star_system: star_system,
      colour: 'Yellow', stellar_type: 'G', stellar_subtype: 2, luminosity: 'V'
    )
    main_world = TerrestrialPlanet.create!(
      orbiting: star, orbit: 1.0,
      size_code: '5', atmosphere_code: 6, hydrographics_code: 5
    )
    StellarObjectTradeCode.create!(stellar_object: main_world, trade_code: trade_codes(:sector_capital))
    star_system.update!(main_world: main_world)

    get map_subsector_url(@subsector)

    assert_response :success
    assert_match(/class="system-name"[^>]*style="fill:#ff0000"/, response.body)
  end

  test 'statistics renders the world statistics partial without a layout' do
    get statistics_subsector_url(@subsector)
    assert_response :success
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@subsector, :statistics)}"
  end

  test 'show includes the highest population world in the summary line when the campaign shows population' do
    campaigns(:one).update!(campaign_type: 'homebrew')

    sector = Sector.create!(name: 'Population Test Sector', x: 9041, y: 9041, skip_subsector_creation: true)
    subsector = Subsector.create!(sector: sector, name: 'Sub A', x: 1, y: 1)
    ul, = subsector.universal_coordinates
    parsec = Parsec.create!(sector: sector, x: ul.x, y: ul.y)
    system = StarSystem.create!(parsec: parsec)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')

    planet = TerrestrialPlanet.new(name: 'Musal', orbiting: star, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = 9
    planet.save!
    planet.population = planet.population.merge('censusPopulation' => 29_400_000_000)
    planet.save!

    get subsector_url(subsector)

    assert_response :success
    assert_select 'a', text: 'Musal'
  end

  test 'show hides population figures when the campaign does not show population' do
    campaigns(:one).update!(campaign_type: 'charted_space')

    get subsector_url(@subsector)

    assert_response :success
    assert_no_match(/populated/, response.body)
  end

  test 'should get edit' do
    get edit_subsector_url(@subsector)
    assert_response :success
  end

  test 'should update subsector' do
    patch subsector_url(@subsector), params: { subsector: { name: @subsector.name, x: @subsector.x, y: @subsector.y } }
    assert_redirected_to subsector_url(@subsector)
  end

  test 'should get defaults_source' do
    get defaults_source_subsector_url(@subsector)
    assert_response :success
  end

  test 'defaults_source shows no default source block when the sector has none' do
    get defaults_source_subsector_url(@subsector)
    assert_response :success
    assert_no_match(/Pulls subsector data from TravellerMap/, response.body)
    assert_no_match(/Campaign-tuned presets/, response.body)
  end

  test 'defaults_source offers TravellerMap when the sector was imported from Traveller Map' do
    @sector.update!(source: 'traveller_map')
    get defaults_source_subsector_url(@subsector)
    assert_response :success
    assert_match(/Pulls subsector data from TravellerMap/, response.body)
    assert_no_match(/Campaign-tuned presets/, response.body)
  end

  test 'defaults_source offers Deepnight when bundled data is available for the sector' do
    sector = Sector.create!(name: 'Deepnight Sector', x: -10, y: -1, abbreviation: 'DN', skip_subsector_creation: true)
    subsector = Subsector.create!(sector: sector, name: 'Sub A', x: 1, y: 1)

    get defaults_source_subsector_url(subsector)

    assert_response :success
    assert_match(/Campaign-tuned presets/, response.body)
    assert_no_match(/Pulls subsector data from TravellerMap/, response.body)
  end

  test 'load_defaults redirects with alert when the sector has no default build source' do
    post load_defaults_subsector_url(@subsector)
    assert_redirected_to subsector_url(@subsector)
    assert_match(/No default build source/, flash[:alert])
  end

  test 'load_defaults loads TravellerMap defaults when that is the sector default source' do
    @sector.update!(source: 'traveller_map')
    stub_request(:get, 'https://travellermap.com/api/sec?sx=1&sy=-1&type=TabDelimited&subsector=A')
      .to_return(status: 200, body: File.read(file_fixture('t5_tab_subsector.txt')))

    post load_defaults_subsector_url(@subsector)

    assert_redirected_to subsector_url(@subsector)
    assert_equal 'Defaults loaded.', flash[:notice]
    @subsector.reload
    assert_equal 'traveller_map', @subsector.build_source
  end

  test 'load_defaults loads Deepnight defaults when that is the sector default source' do
    sector = Sector.create!(name: 'Deepnight Sector', x: -10, y: -1, abbreviation: 'DN', skip_subsector_creation: true)
    subsector = Subsector.create!(sector: sector, name: 'Sub A', x: 1, y: 1)

    post load_defaults_subsector_url(subsector)

    assert_redirected_to subsector_url(subsector)
    assert_equal 'Defaults loaded.', flash[:notice]
    subsector.reload
    assert_equal 'deepnight_books', subsector.build_source
  end

  test 'upload_t5 sets build from an uploaded file' do
    subsector = subsectors(:subsector_3_1) # letter C, matching the fixture's hex range
    file = Rack::Test::UploadedFile.new(file_fixture('t5_tab_subsector.txt'), 'text/plain')

    post upload_t5_subsector_url(subsector), params: { t5_file: file }

    assert_redirected_to subsector_url(subsector)
    subsector.reload
    assert_equal 'uploaded', subsector.build_source
    assert_match(/Efate/, subsector.build)
  end

  test 'upload_t5 redirects with alert when no file given' do
    post upload_t5_subsector_url(@subsector)
    assert_redirected_to subsector_url(@subsector)
    assert_match(/choose a T5/, flash[:alert])
  end

  test 'upload_t5 redirects with alert when the file has no systems' do
    file = Rack::Test::UploadedFile.new(StringIO.new("Hex\tName\n"), 'text/plain', original_filename: 'subsector.txt')

    post upload_t5_subsector_url(@subsector), params: { t5_file: file }

    assert_redirected_to subsector_url(@subsector)
    assert_match(/No systems found/, flash[:alert])
  end

  test 'upload_t5 redirects with alert when the file has no rows for this subsector' do
    file = Rack::Test::UploadedFile.new(file_fixture('t5_tab_subsector.txt'), 'text/plain') # subsector C hexes

    post upload_t5_subsector_url(@subsector), params: { t5_file: file } # @subsector is letter A

    assert_redirected_to subsector_url(@subsector)
    assert_match(/No systems found/, flash[:alert])
    @subsector.reload
    assert_nil @subsector.build_source
  end
end
