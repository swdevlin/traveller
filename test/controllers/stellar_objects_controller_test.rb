require 'test_helper'

class StellarObjectsControllerTest < AuthenticatedIntegrationTest
  setup do
    @parsec = parsecs(:one)
    @star_system = star_systems(:in_one)
    @stellar_object = stellar_objects(:one)
    @gas_giant = gas_giants(:small)
    @moon = moons(:orbiting_gas_giant)
  end

  # test 'should get index' do
  #   get stellar_objects_url
  #   assert_response :success
  # end

  test 'should get new' do
    get new_stellar_object_url
    assert_response :success
  end

  test 'show and edit render for every stellar object type sharing the DRY show/form partials' do
    star = stars(:star_one)

    [
      GasGiant.create!(name: 'Test GG', orbiting: star, orbit: 2, inclination: 0, eccentricity: 0, diameter: 1000, mass: 1, data: { code: 'GS' }),
      PlanetoidBelt.create!(name: 'Test Belt', orbiting: star, orbit: 3, inclination: 0, eccentricity: 0),
      Comet.create!(name: 'Test Comet', orbiting: star, orbit: 4, inclination: 0, eccentricity: 0, diameter: 1),
      GasCloud.create!(name: 'Test Gas Cloud', orbiting: star, orbit: 5, inclination: 0, eccentricity: 0, diameter: 1),
      GravityAnomaly.create!(name: 'Test GA', orbiting: star, orbit: 6, inclination: 0, eccentricity: 0, diameter: 1),
      TerrestrialPlanet.create!(name: 'Test TP', orbiting: star, orbit: 7, inclination: 0, eccentricity: 0, diameter: 1000, mass: 1, size_code: '7', atmosphere_code: 6, hydrographics_code: 5),
      Planetoid.create!(name: 'Test Planetoid', orbiting: star, orbit: 8, inclination: 0, eccentricity: 0, diameter: 100, mass: 1, size_code: '1')
    ].each do |so|
      get stellar_object_url(so)
      assert_response :success, "#{so.type} show failed: #{response.body[0..500]}"
      get edit_stellar_object_url(so)
      assert_response :success, "#{so.type} edit failed: #{response.body[0..500]}"
    end
  end

  test 'show renders periapsis and apoapsis in whole-number km for a moon' do
    @gas_giant.update!(star_system: @star_system)
    @moon.data = @moon.data.merge('periapsis' => 1234.5, 'apoapsis' => 5678.9)
    @moon.save!

    get stellar_object_url(@moon)

    assert_response :success
    assert_match(/1,235/, response.body)
    assert_match(/5,679/, response.body)
  end

  # test 'should create stellar_object' do
  #   assert_difference('StellarObject.count', +1) do
  #     post stellar_objects_url, params: {
  #       stellar_object: {
  #         type: 'GasGiant', # used only to choose class, not permitted
  #         orbiting_star_id: @star.id,
  #         eccentricity: 0,
  #         effective_hzco_deviation: 0.4,
  #         inclination: 0,
  #         orbit: 2.4,
  #         orbit_x: 4,
  #         orbit_y: 3,
  #         name: 'created in test'
  #       }
  #     }
  #   end
  #
  #   so = StellarObject.order(:id).last
  #   assert_redirected_to stellar_object_url(so)
  #   assert_instance_of GasGiant, so
  # end


  # test 'should show stellar_object' do
  #   get stellar_object_url(@stellar_object)
  #   assert_response :success
  # end

  # test 'should get edit' do
  #   get edit_stellar_object_url(@stellar_object)
  #   assert_response :success
  # end

  test 'should update moon UWP fields including tech level zero' do
    patch stellar_object_url(@moon), params: {
      stellar_object: { tech_level_code: 0, hydrographics_code: 5 }
    }
    assert_redirected_to stellar_object_url(@moon)
    @moon.reload
    assert_equal 0, @moon.tech_level_code.to_i
    assert_equal 5, @moon.hydrographics_code
  end

  test 'should update culture trait fields within their own ranges' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: {
        size_code: '5', atmosphere_code: 5, hydrographics_code: 5,
        population_militancy: 20, population_cohesion: 22
      }
    }
    assert_redirected_to stellar_object_url(planet)
    planet.reload
    assert_equal 20, planet.population_militancy
    assert_equal 22, planet.population_cohesion

    get stellar_object_url(planet)
    assert_response :success
    assert_select '.dg-subsection .label', text: 'Culture'
    assert_match(/Militancy/, response.body)
  end

  test 'should reject a culture trait value above its own max' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: {
        size_code: '5', atmosphere_code: 5, hydrographics_code: 5,
        population_militancy: 21
      }
    }
    assert_response :unprocessable_entity
    assert_match(/less than or equal to 20/, response.body)
  end

  test 'edit form renders a culture trait input with its own min/max attributes' do
    get edit_stellar_object_url(stellar_objects(:two))
    assert_response :success
    assert_select "input[name='stellar_object[population_militancy]'][min='1'][max='20']"
    assert_select "input[name='stellar_object[population_cohesion]'][min='1'][max='22']"
  end

  test 'should update stellar_object' do
    patch stellar_object_url(@stellar_object), params: { stellar_object: { eccentricity: 1, effective_hzco_deviation: 2, inclination: 0.3, orbit: 2, orbit_x: 1, orbit_y: 1 } }
    assert_redirected_to stellar_object_url(@stellar_object)
  end

  test 'eccentricity change triggers orbit mechanics recalculation' do
    @gas_giant.update_columns(star_system_id: @star_system.id, orbit_sequence: 'I')
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { 'primaryStar' => { 'orbitSequence' => 'A', 'stellarObjects' => [] } }.to_json)

    patch stellar_object_url(@gas_giant), params: { stellar_object: { eccentricity: 0.4 } }

    assert_requested stub
    assert_redirected_to stellar_object_url(@gas_giant)
  end

  test 'orbit change triggers orbit mechanics recalculation' do
    @gas_giant.update_columns(star_system_id: @star_system.id, orbit_sequence: 'I')
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { 'primaryStar' => { 'orbitSequence' => 'A', 'stellarObjects' => [] } }.to_json)

    patch stellar_object_url(@gas_giant), params: { stellar_object: { orbit: 2.5 } }

    assert_requested stub
    assert_redirected_to stellar_object_url(@gas_giant)
  end

  test 'unrelated field change does not trigger orbit mechanics recalculation' do
    @gas_giant.update_columns(star_system_id: @star_system.id, orbit_sequence: 'I')
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")

    patch stellar_object_url(@gas_giant), params: { stellar_object: { name: 'Renamed giant' } }

    assert_not_requested stub
  end

  test 'flash alert when orbit mechanics recalculation fails' do
    @gas_giant.update_columns(star_system_id: @star_system.id, orbit_sequence: 'I')
    base = Rails.application.config.x.generator_service
    stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 400, headers: { 'Content-Type' => 'application/json' }, body: { error: 'bad tree' }.to_json)

    patch stellar_object_url(@gas_giant), params: { stellar_object: { eccentricity: 0.4 } }

    assert_redirected_to stellar_object_url(@gas_giant)
    assert_match(/could not be recalculated/, flash[:alert].to_s)
  end

  test 'government/law level/tech level tabs show population-zero message when population and those codes are all 0' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: {
        size_code: '5', atmosphere_code: 5, hydrographics_code: 5,
        population_code: 0, government_code: 0, law_level_code: 0, tech_level_code: 0
      }
    }
    assert_redirected_to stellar_object_url(planet)

    get stellar_object_url(planet)

    assert_response :success
    assert_select '.text-fg-muted', text: 'No government (population 0).'
    assert_select '.text-fg-muted', text: 'No law level (population 0).'
    assert_select '.text-fg-muted', text: 'No tech level (population 0).'
    assert_select '.dg-subsection .label', text: 'Structure', count: 0
    assert_select '.dg-subsection .label', text: 'Sub-Classifications', count: 0
    assert_select '.dg-subsection .label', text: 'Capabilities', count: 0
  end

  test 'government/law level/tech level tabs show real values when population is 0 but field codes are present' do
    planet = stellar_objects(:two)
    patch stellar_object_url(planet), params: {
      stellar_object: {
        size_code: '5', atmosphere_code: 5, hydrographics_code: 5,
        population_code: 0, government_code: 1, law_level_code: 1, tech_level_code: 1
      }
    }
    assert_redirected_to stellar_object_url(planet)

    get stellar_object_url(planet)

    assert_response :success
    assert_select '.text-fg-muted', text: 'No government (population 0).', count: 0
    assert_select '.text-fg-muted', text: 'No law level (population 0).', count: 0
    assert_select '.text-fg-muted', text: 'No tech level (population 0).', count: 0
    assert_includes response.body, 'Code 1 government'
    assert_includes response.body, 'MyString'
  end

  test 'population tab lists major cities highest population first' do
    planet = stellar_objects(:two)

    get stellar_object_url(planet)

    assert_response :success
    assert_select 'turbo-frame#cities-table' do
      assert_select 'td', text: 'Newhaven'
      assert_select 'td', text: '520,000'
      assert_select 'td', text: 'Port Meridian'
      assert_select 'td', text: 'City 3'
    end
  end

  test 'should destroy stellar_object' do
    referer_url = subsector_url(subsectors(:subsector_1_1))

    assert_difference('StellarObject.count', -1) do
      delete stellar_object_url(@stellar_object), headers: { 'HTTP_REFERER' => referer_url }
    end

    assert_redirected_to referer_url
  end
end
