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
end
