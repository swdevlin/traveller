require 'test_helper'

class HelpControllerTest < AuthenticatedIntegrationTest
  # Ahoy skips bot-looking user agents, which includes the Rails test client's default.
  BROWSER = { 'User-Agent' => 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36' }.freeze

  test 'should get index' do
    get help_url
    assert_response :success
  end

  test 'should get subsector_build_specification' do
    get help_page_url('subsector_build_specification')
    assert_response :success
  end

  test 'should get star_system_build_specification' do
    get help_page_url('star_system_build_specification')
    assert_response :success
  end

  test 'should get starmap_display' do
    get help_page_url('starmap_display')
    assert_response :success
  end

  test 'should get commerce_show' do
    get help_page_url('commerce_show')
    assert_response :success
  end

  test 'should get terrestrial_planet_show' do
    get help_page_url('terrestrial_planet_show')
    assert_response :success
  end

  test 'should get moon_show' do
    get help_page_url('moon_show')
    assert_response :success
  end

  test 'should get planetoid_belt_show' do
    get help_page_url('planetoid_belt_show')
    assert_response :success
  end

  test 'should get stellar_objects_show' do
    get help_page_url('stellar_objects_show')
    assert_response :success
  end

  test 'should get stars_show' do
    get help_page_url('stars_show')
    assert_response :success
    assert_select '.page-title', text: /Star Survey/
  end

  test 'campaign_settings documents the orbit map endpoint' do
    get help_page_url('campaign_settings')
    assert_response :success
    assert_select 'dt', text: 'Star Orbit Map Endpoint'
  end

  test 'the star page help link opens the star help page' do
    get star_url(stars(:star_one))

    assert_select "a[href='#{help_page_path('stars_show', campaign_slug: campaigns(:one).slug)}']"
  end

  test 'a help page view from a campaign is tracked with its page' do
    assert_difference -> { Ahoy::Event.where(name: 'Viewed help').count }, 1 do
      get help_page_url('stars_show', campaign_slug: campaigns(:one).slug), headers: BROWSER
    end

    event = Ahoy::Event.where(name: 'Viewed help').last
    assert_equal 'stars_show', event.properties['page']
    assert_equal campaigns(:one).id, event.properties['campaign_id']
  end

  test 'the help index is tracked as the index page' do
    get help_url(campaign_slug: campaigns(:one).slug), headers: BROWSER

    assert_equal 'index', Ahoy::Event.where(name: 'Viewed help').last.properties['page']
  end

  test 'a help view without a campaign is not tracked' do
    assert_no_difference -> { Ahoy::Event.where(name: 'Viewed help').count } do
      get help_page_url('stars_show', campaign_slug: nil), headers: BROWSER
    end
  end

  test 'a help view by a signed-out visitor is not tracked' do
    sign_out

    assert_no_difference -> { Ahoy::Event.where(name: 'Viewed help').count } do
      get help_page_url('stars_show', campaign_slug: campaigns(:one).slug), headers: BROWSER
    end
    assert_response :success
  end
end
