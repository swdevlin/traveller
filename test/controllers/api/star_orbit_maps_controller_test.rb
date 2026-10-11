# frozen_string_literal: true

require 'test_helper'

class Api::StarOrbitMapsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    @star = stars(:star_one)
    @giant = GasGiant.create!(name: 'Big', orbiting: @star, orbit: 2, au: 1.0, code: 'GM')
    @token_headers = { 'Authorization' => "Bearer #{@campaign.api_token}" }
  end

  def orbit_map_url_for(format: nil, **params)
    api_star_orbit_map_url(@star, format: format, campaign_slug: @campaign.slug, **params)
  end

  test 'without credentials it is unauthorised' do
    get orbit_map_url_for

    assert_response :unauthorized
  end

  test 'with a wrong token it is unauthorised' do
    get orbit_map_url_for, headers: { 'Authorization' => 'Bearer nope' }

    assert_response :unauthorized
  end

  test 'svg is the default format' do
    get orbit_map_url_for, headers: @token_headers

    assert_response :success
    assert_equal 'image/svg+xml', response.media_type
  end

  test 'a token gets an svg with no links, and the images inlined' do
    get orbit_map_url_for(format: :svg), headers: @token_headers

    svg = Nokogiri::XML(response.body)
    assert_empty svg.css('a')
    assert_includes response.body, 'href="data:image/webp;base64,'
    assert_not_includes response.body, 'href="/stellar_objects/'
  end

  test 'a logged-in user gets an svg that links to the app' do
    sign_in_as users(:one)

    get orbit_map_url_for(format: :svg)

    assert_response :success
    hrefs = Nokogiri::XML(response.body).css('a').map { |a| a['href'] }
    assert_includes hrefs, stellar_object_path(@giant, campaign_slug: @campaign.slug)
  end

  test 'a token wins over a session, so there are still no links' do
    sign_in_as users(:one)

    get orbit_map_url_for(format: :svg), headers: @token_headers

    assert_empty Nokogiri::XML(response.body).css('a')
  end

  test 'webp is served to a token' do
    get orbit_map_url_for(format: :webp), headers: @token_headers

    assert_response :success
    assert_equal 'image/webp', response.media_type
    assert_equal 'RIFF', response.body[0, 4]
  end

  test 'the theme param selects the colours' do
    get orbit_map_url_for(format: :svg, theme: 'aslan'), headers: @token_headers

    assert_includes response.body, %(fill="#{OrbitMapTheme.palette('aslan').panel}")
  end

  test 'an unknown theme falls back to dark' do
    get orbit_map_url_for(format: :svg, theme: 'bogus'), headers: @token_headers

    assert_includes response.body, %(fill="#{OrbitMapTheme.palette('dark').panel}")
  end

  test 'it is inline unless a download is asked for' do
    get orbit_map_url_for(format: :webp), headers: @token_headers
    assert_match(/\Ainline/, response.headers['Content-Disposition'])

    get orbit_map_url_for(format: :webp, download: 1), headers: @token_headers
    assert_match(/\Aattachment/, response.headers['Content-Disposition'])
    assert_includes response.headers['Content-Disposition'], @star.orbit_map_download_filename
  end

  test 'the svg download is named like the webp, with an svg extension' do
    get orbit_map_url_for(format: :svg, download: 1), headers: @token_headers

    assert_includes response.headers['Content-Disposition'], @star.orbit_map_download_filename('svg')
  end

  test 'other formats are not acceptable' do
    get orbit_map_url_for(format: :png), headers: @token_headers

    assert_response :not_acceptable
  end

  test 'an unknown star is not found' do
    get api_star_orbit_map_url(0, format: :svg, campaign_slug: @campaign.slug), headers: @token_headers

    assert_response :not_found
  end

  test "another campaign's token does not work" do
    get orbit_map_url_for(format: :svg),
        headers: { 'Authorization' => "Bearer #{campaigns(:two).api_token}" }

    assert_response :unauthorized
  end
end
