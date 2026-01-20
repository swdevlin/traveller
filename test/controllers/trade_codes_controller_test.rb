require 'test_helper'

class TradeCodesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @trade_code = trade_codes(:tc1)
  end

  test 'should get index' do
    get trade_codes_url
    assert_response :success
  end

  test 'should get new' do
    get new_trade_code_url
    assert_response :success
  end

  test 'should create trade_code' do
    assert_difference('TradeCode.count') do
      post trade_codes_url, params: { trade_code: { code: 'XX', definition: 'A new one' } }
    end

    assert_redirected_to trade_code_url(TradeCode.last)
  end

  test 'should show trade_code' do
    get trade_code_url(@trade_code)
    assert_response :success
  end

  test 'should get edit' do
    get edit_trade_code_url(@trade_code)
    assert_response :success
  end

  test 'should update trade_code' do
    patch trade_code_url(@trade_code), params: { trade_code: { code: @trade_code.code, definition: 'new definition' } }
    assert_redirected_to trade_code_url(@trade_code)
  end

  test 'should destroy trade_code' do
    assert_difference('TradeCode.count', -1) do
      delete trade_code_url(@trade_code)
    end

    assert_redirected_to trade_codes_url
  end
end
