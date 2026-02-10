require 'test_helper'

class HelpControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get help_url
    assert_response :success
  end

  test 'should get subsector_build_specification' do
    get help_subsector_build_specification_url
    assert_response :success
  end

  test 'should get star_system_build_specification' do
    get help_star_system_build_specification_url
    assert_response :success
  end
end
