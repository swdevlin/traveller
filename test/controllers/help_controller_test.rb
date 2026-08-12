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
end
