require 'test_helper'

class StarmapData::ObjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @slug = campaigns(:one).slug
    @gas_giant = stellar_objects(:moons_test_gas_giant)
    sign_in_as users(:one)
  end

  test 'serves an opened object with a count of its moons and its rings' do
    Ring.create!(name: 'Ring', orbiting: @gas_giant, orbit: 0.9, data: { 'span' => 0.25 })

    get "/c/#{@slug}/starmap/data/objects/#{@gas_giant.id}", as: :json

    assert_response :success
    assert_equal 10, response.parsed_body['orbit_type']
    assert_equal 2, response.parsed_body['moon_count']
    assert_not response.parsed_body.key?('moons')
    assert_equal [{ 'name' => 'Ring', 'orbit' => 0.9, 'span' => 0.25 }],
                 response.parsed_body['rings'].map { |r| r.slice('name', 'orbit', 'span') }
  end

  test 'carries the detail the system tree leaves out' do
    get "/c/#{@slug}/starmap/data/objects/#{@gas_giant.id}", as: :json

    assert response.parsed_body.key?('created_at')
  end

  test 'a moon is opened as a terrestrial planet that is a moon' do
    moon = stellar_objects(:moons_test_significant_moon)

    get "/c/#{@slug}/starmap/data/objects/#{moon.id}", as: :json

    assert_response :success
    assert_equal 11, response.parsed_body['orbit_type']
    assert_equal true, response.parsed_body['is_moon']
    assert_not response.parsed_body.key?('moon_count')
  end

  test 'lists the moons as a row each, in a page' do
    get "/c/#{@slug}/starmap/data/objects/#{@gas_giant.id}/moons", as: :json

    assert_response :success
    assert_equal 2, response.parsed_body['count']
    assert_equal %w[id name orbit orbit_sequence uwp], response.parsed_body['moons'].first.keys.sort
    assert_equal @gas_giant.diameter, response.parsed_body['parent_diameter_km']
  end

  test 'lists the rings beside the moons' do
    Ring.create!(name: 'Ring', orbiting: @gas_giant, orbit: 0.9, data: { 'span' => 0.25 })

    get "/c/#{@slug}/starmap/data/objects/#{@gas_giant.id}/moons", as: :json

    assert_equal [0.25], response.parsed_body['rings'].map { |r| r['span'] }
    assert_equal 2, response.parsed_body['moons'].size
  end

  test 'moons of a system the players have not found are withheld from them' do
    reset!
    @gas_giant.star_system.update!(known: false, survey_index: 0)

    get "/c/#{@slug}/starmap/data/objects/#{@gas_giant.id}/moons", as: :json

    assert_response :not_found
  end

  test 'an unknown object is a 404' do
    get "/c/#{@slug}/starmap/data/objects/0", as: :json

    assert_response :not_found
  end

  test 'the API object carries neither moons nor rings' do
    get "/c/#{@slug}/api/stellar_objects/#{@gas_giant.id}", as: :json

    assert_not response.parsed_body.key?('rings')
  end
end
