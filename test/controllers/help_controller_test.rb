require 'test_helper'

class HelpControllerTest < ActionDispatch::IntegrationTest
  test 'should get index' do
    get help_url
    assert_response :success
  end

  test 'should get build_specification' do
    get help_build_specification_url
    assert_response :success
  end
end
