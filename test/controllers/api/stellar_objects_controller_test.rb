require 'test_helper'

class Api::StellarObjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
    @gas_giant = stellar_objects(:moons_test_gas_giant)
  end

  test 'referee sees all moons regardless of survey status' do
    sign_in_as users(:one)

    get api_stellar_object_moons_url(@gas_giant), as: :json

    assert_response :success
    assert_equal 2, response.parsed_body['count']
  end

  test 'player sees moons when the star system is known' do
    @gas_giant.star_system.update!(known: true)

    get api_stellar_object_moons_url(@gas_giant), as: :json

    assert_response :success
    assert_equal 2, response.parsed_body['count']
  end

  test 'player sees moons when the star system survey index is at least 10' do
    @gas_giant.star_system.update!(survey_index: 12)

    get api_stellar_object_moons_url(@gas_giant), as: :json

    assert_response :success
    assert_equal 2, response.parsed_body['count']
  end

  test 'player is denied when the star system is unknown and unsurveyed' do
    get api_stellar_object_moons_url(@gas_giant), as: :json

    assert_response :not_found
  end

  test 'significant_only filters out size 0/S moons' do
    @gas_giant.star_system.update!(known: true)

    get api_stellar_object_moons_url(@gas_giant, significant_only: 1), as: :json

    assert_response :success
    body = response.parsed_body
    assert_equal 1, body['count']
    assert_equal 'Significant Moon', body['moons'].first['name']
  end

  test 'returns 404 for a stellar object that does not exist' do
    get api_stellar_object_moons_url(999_999), as: :json

    assert_response :not_found
  end
end
