require 'test_helper'

class StarsControllerTest < AuthenticatedIntegrationTest
  setup do
    @star = stars(:star_one)
  end

  test 'should update star' do
    patch star_url(@star), params: { star: { mass: 1.6 } }
    assert_redirected_to star_url(@star)
  end

  test 'eccentricity change triggers orbit mechanics recalculation' do
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { 'primaryStar' => { 'orbitSequence' => @star.orbit_sequence, 'stellarObjects' => [] } }.to_json)

    patch star_url(@star), params: { star: { eccentricity: 0.4 } }

    assert_requested stub
    assert_redirected_to star_url(@star)
  end

  test 'orbit change triggers orbit mechanics recalculation' do
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 200, headers: { 'Content-Type' => 'application/json' }, body: { 'primaryStar' => { 'orbitSequence' => @star.orbit_sequence, 'stellarObjects' => [] } }.to_json)

    patch star_url(@star), params: { star: { orbit: 2.5 } }

    assert_requested stub
    assert_redirected_to star_url(@star)
  end

  test 'unrelated field change does not trigger orbit mechanics recalculation' do
    base = Rails.application.config.x.generator_service
    stub = stub_request(:post, "#{base}/orbit_mechanics")

    patch star_url(@star), params: { star: { mass: 1.6 } }

    assert_not_requested stub
  end

  test 'flash alert when orbit mechanics recalculation fails' do
    base = Rails.application.config.x.generator_service
    stub_request(:post, "#{base}/orbit_mechanics")
      .to_return(status: 400, headers: { 'Content-Type' => 'application/json' }, body: { error: 'bad tree' }.to_json)

    patch star_url(@star), params: { star: { eccentricity: 0.4 } }

    assert_redirected_to star_url(@star)
    assert_match(/could not be recalculated/, flash[:alert].to_s)
  end

  test 'update stores stellar subtype as an integer' do
    patch star_url(@star), params: { star: { stellar_subtype: '4' } }

    assert_redirected_to star_url(@star)
    assert_equal 4, @star.reload.data['stellar_subtype']
  end

  test 'show renders the star map above the orbiting table' do
    get star_url(@star)

    assert_response :success
    assert_select '.subway-map-container svg.subway-map'
    assert_select 'button[title="Copy public map link"]'
    assert_operator response.body.index('subway-map-container'), :<, response.body.index('Orbiting bodies')
  end

  test 'map.svg is served to a logged-out visitor with the extensionless token' do
    token = campaigns(:one).token_for(map_star_path(@star))
    sign_out

    get map_star_path(@star, format: :svg), params: { token: token }

    assert_response :success
    assert_equal 'image/svg+xml', response.media_type
  end

  test 'map.webp is served to a logged-in user' do
    get map_star_url(@star, format: :webp)

    assert_response :success
    assert_equal 'image/webp', response.media_type
  end

  test 'map is forbidden to a logged-out visitor without a valid token' do
    sign_out

    get map_star_path(@star, format: :svg), params: { token: 'wrong' }

    assert_response :forbidden
  end

  test 'show has an orbit map link that opens in the modal frame' do
    get star_url(@star)

    assert_select "a[href='#{orbit_map_modal_star_path(@star, campaign_slug: campaigns(:one).slug)}'][data-turbo-frame='modal']"
  end

  test 'orbit map modal shows the linked map and a download link' do
    body = GasGiant.create!(name: 'Big', orbiting: @star, orbit: 2, au: 1.0, code: 'GM')

    get orbit_map_modal_star_url(@star)

    assert_response :success
    assert_select 'svg a[href=?]', stellar_object_path(body, campaign_slug: campaigns(:one).slug)
    assert_select 'a[download=?]', @star.orbit_map_download_filename do |links|
      assert_match(/orbit_map\.webp/, links.first['href'])
    end
  end

  test 'orbit map modal uses the theme cookie' do
    cookies[:theme] = 'aslan'

    get orbit_map_modal_star_url(@star)

    assert_includes response.body, %(fill="#{OrbitMapTheme.palette('aslan').panel}")
  end

  test 'orbit_map.webp is served to a logged-in user' do
    get orbit_map_star_url(@star, format: :webp)

    assert_response :success
    assert_equal 'image/webp', response.media_type
  end

  test 'orbit map requires a logged-in user' do
    sign_out

    get orbit_map_modal_star_url(@star)
    assert_response :redirect

    get orbit_map_star_url(@star, format: :webp)
    assert_response :redirect
  end

  test 'map is not found for a star with no star system' do
    @star.update_column(:star_system_id, nil)

    get map_star_url(@star, format: :svg)

    assert_response :not_found
  end
end
