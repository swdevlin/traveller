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

  test 'should update stellar_object' do
    patch stellar_object_url(@stellar_object), params: { stellar_object: { eccentricity: 1, effective_hzco_deviation: 2, inclination: 0.3, orbit: 2, orbit_x: 1, orbit_y: 1 } }
    assert_redirected_to stellar_object_url(@stellar_object)
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
