require 'test_helper'

class HelpControllerTest < AuthenticatedIntegrationTest
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
end
