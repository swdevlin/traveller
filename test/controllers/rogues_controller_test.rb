require 'test_helper'

class RogueControllerTest < ActionDispatch::IntegrationTest
  test 'should get create' do
    get rogue_create_url
    assert_response :success
  end

  test 'should get destroy' do
    get rogue_destroy_url
    assert_response :success
  end

  test 'should get show' do
    get rogue_show_url
    assert_response :success
  end

  test 'should get index' do
    get rogue_index_url
    assert_response :success
  end
end
