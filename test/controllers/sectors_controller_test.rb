require 'test_helper'

class SectorsControllerTest < AuthenticatedIntegrationTest
  setup do
    @sector = sectors(:one)
  end

  test 'should get index' do
    get sectors_url
    assert_response :success
  end

  test 'should get new' do
    get new_sector_url
    assert_response :success
  end

  test 'should create sector' do
    assert_difference('Sector.count') do
      post sectors_url, params: { sector: { abbreviation: @sector.abbreviation, name: @sector.name, x: 12, y: 12 } }
    end

    assert_redirected_to sector_url(Sector.last)
  end

  test 'should create sector with an uploaded T5 file' do
    file = Rack::Test::UploadedFile.new(file_fixture('t5_tab_sector.txt'), 'text/plain')

    assert_difference('Sector.count') do
      post sectors_url, params: {
        sector: {
          abbreviation: @sector.abbreviation, name: @sector.name, x: 13, y: 13,
          default_build_spec: SectorsController::SETTLED_BUILD_SPEC
        },
        t5_file: file
      }
    end

    assert_redirected_to sector_url(Sector.last)
  end

  test 'should show sector' do
    get sector_url(@sector)
    assert_response :success
  end

  test 'edit is forbidden for a logged-in user who does not referee this campaign' do
    sign_out
    sign_in_as users(:two)
    get edit_sector_url(@sector)
    assert_response :forbidden
  end

  test 'map is reachable for a logged-in user who does not referee this campaign, at the player variant' do
    get map_sector_url(@sector, format: :svg)
    owner_etag = response.headers['ETag']

    sign_out
    sign_in_as users(:two)
    get map_sector_url(@sector, format: :svg)

    assert_response :success
    refute_equal owner_etag, response.headers['ETag']
  end

  test 'statistics renders the world statistics partial without a layout' do
    get statistics_sector_url(@sector)
    assert_response :success
    assert_select "turbo-frame##{ActionView::RecordIdentifier.dom_id(@sector, :statistics)}"
  end

  test 'show includes the highest population world in the summary line' do
    sector = Sector.create!(name: 'Population Test Sector', x: 9030, y: 9030, skip_subsector_creation: true)
    parsec = Parsec.create!(sector: sector, x: sector.x * 32, y: sector.y * 40)
    system = StarSystem.create!(parsec: parsec)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')

    planet = TerrestrialPlanet.new(name: 'Musal', orbiting: star, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = 9
    planet.save!
    planet.population = planet.population.merge('censusPopulation' => 29_400_000_000)
    planet.save!

    get sector_url(sector)

    assert_response :success
    assert_select 'a', text: 'Musal'
  end

  test 'show reports incomplete census data instead of a misleading zero population' do
    sector = Sector.create!(name: 'Census Test Sector', x: 9031, y: 9031, skip_subsector_creation: true)
    parsec = Parsec.create!(sector: sector, x: sector.x * 32, y: sector.y * 40)
    system = StarSystem.create!(parsec: parsec)
    star = Star.create!(name: 'Star', star_system: system, parsec: parsec, type: 'Star')

    planet = TerrestrialPlanet.new(name: 'Uncensused', orbiting: star, orbit: 1, size_code: '5')
    planet.atmosphere_code = 6
    planet.hydrographics_code = 5
    planet.population_code = 10
    planet.save!

    get sector_url(sector)

    assert_response :success
    assert_match 'incomplete census data', response.body
    assert_no_match '0 population', response.body
  end

  test 'should get edit' do
    get edit_sector_url(@sector)
    assert_response :success
  end

  test 'should update sector' do
    patch sector_url(@sector), params: { sector: { abbreviation: @sector.abbreviation, name: @sector.name, x: @sector.x, y: @sector.y } }
    assert_redirected_to sector_url(@sector)
  end

  test 'should destroy sector' do
    assert_difference('Sector.kept.count', -1) do
      delete sector_url(@sector)
    end

    assert_redirected_to sectors_url
  end

  test 'defaults_source shows no default source block when the sector has none' do
    get defaults_source_sector_url(@sector)
    assert_response :success
    assert_no_match(/Pulls subsector data from TravellerMap/, response.body)
    assert_no_match(/Campaign-tuned presets/, response.body)
  end

  test 'defaults_source offers TravellerMap when the sector was imported from Traveller Map' do
    @sector.update!(source: 'traveller_map')
    get defaults_source_sector_url(@sector)
    assert_response :success
    assert_match(/Pulls subsector data from TravellerMap/, response.body)
    assert_no_match(/Campaign-tuned presets/, response.body)
  end

  test 'defaults_source offers Deepnight when bundled data is available for the sector' do
    sector = Sector.create!(name: 'Deepnight Sector', x: -10, y: -1, abbreviation: 'DN', skip_subsector_creation: true)
    get defaults_source_sector_url(sector)
    assert_response :success
    assert_match(/Campaign-tuned presets/, response.body)
    assert_no_match(/Pulls subsector data from TravellerMap/, response.body)
  end

  test 'load_defaults redirects with alert when the sector has no default build source' do
    post load_defaults_sector_url(@sector)
    assert_redirected_to sector_url(@sector)
    assert_match(/No default build source/, flash[:alert])
  end

  test 'load_defaults loads Deepnight defaults into subsectors when that is the default source' do
    sector = Sector.create!(name: 'Deepnight Sector', x: -10, y: -1, abbreviation: 'DN', skip_subsector_creation: true)
    subsector_a = Subsector.create!(sector: sector, name: 'Sub A', x: 1, y: 1)

    post load_defaults_sector_url(sector)

    assert_redirected_to sector_url(sector)
    assert_match(/Deepnight defaults loaded/, flash[:notice])
    subsector_a.reload
    assert_equal 'deepnight_books', subsector_a.build_source
  end

  test 'upload_t5 loads defaults into matching subsectors' do
    subsector_a = subsectors(:subsector_1_1) # letter A
    subsector_b = subsectors(:subsector_2_1) # letter B

    file = Rack::Test::UploadedFile.new(file_fixture('t5_tab_sector.txt'), 'text/plain')

    post upload_t5_sector_url(@sector), params: { t5_file: file }

    assert_redirected_to sector_url(@sector)
    subsector_a.reload
    subsector_b.reload
    assert_equal 'uploaded', subsector_a.build_source
    assert_match(/Zeycude/, subsector_a.build)
    assert_equal 'uploaded', subsector_b.build_source
    assert_match(/Condyole/, subsector_b.build)
  end

  test 'upload_t5 redirects with alert when no file given' do
    post upload_t5_sector_url(@sector)
    assert_redirected_to sector_url(@sector)
    assert_match(/choose a T5/, flash[:alert])
  end

  test 'import_jump_routes creates jump routes and links on success' do
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1')
      .to_return(status: 200, body: {
        'Routes' => [{ 'Start' => '0101', 'End' => '0202', 'EndOffsetY' => -1 }]
      }.to_json)

    assert_difference ['JumpRoute.count', 'JumpRouteLink.count'], 1 do
      post import_jump_routes_sector_url(@sector)
    end

    assert_redirected_to sector_url(@sector)
    assert_match(/1 new link/, flash[:notice])
    assert JumpRoute.find_by(travellermap_allegiance_code: 'Im')
  end

  test 'import_jump_routes shows an alert and creates nothing when the fetch fails' do
    stub_request(:get, 'https://travellermap.com/api/metadata?sx=1&sy=-1').to_return(status: 500, body: 'boom')

    assert_no_difference ['JumpRoute.count', 'JumpRouteLink.count'] do
      post import_jump_routes_sector_url(@sector)
    end

    assert_redirected_to sector_url(@sector)
    assert flash[:alert].present?
  end

  test 'should get sector map' do
    get map_sector_url(@sector)
    assert_response :success
  end

  test 'should get poster with capital colours configured' do
    campaigns(:one).update!(sector_capital_colour: '#ff0000', subsector_capital_colour: '#00ff00')

    get poster_sector_url(@sector)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end

  test 'should get poster with no capital colours configured' do
    campaigns(:one).update!(sector_capital_colour: nil, subsector_capital_colour: nil)

    get poster_sector_url(@sector)

    assert_response :success
    assert_equal 'application/pdf', response.media_type
  end
end
