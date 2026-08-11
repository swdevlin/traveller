# frozen_string_literal: true

require 'test_helper'

class TradeGoodsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    self.default_url_options = { campaign_slug: @campaign.slug }
  end

  test 'edit redirects to login when not authenticated' do
    get edit_trade_goods_url
    assert_response :redirect
  end

  test 'edit renders the priceable goods table' do
    sign_in_as users(:one)

    get edit_trade_goods_url

    assert_response :success
    assert_select 'input[name="campaign[trade_good_base_prices][11]"][step="1000"]'
    assert_select 'input[name="campaign[trade_good_base_prices][14]"][step="100"]'
    assert_select 'input[name="campaign[trade_good_base_prices][21]"][step="10000"]'
    refute_select 'input[name="campaign[trade_good_base_prices][66]"]'
  end

  test 'edit populates the price field with the default price' do
    sign_in_as users(:one)

    get edit_trade_goods_url

    assert_select 'input[name="campaign[trade_good_base_prices][11]"][value="20000"]'
  end

  test 'edit populates the price field with a campaign price' do
    @campaign.update!(trade_good_base_prices: { '11' => '99000' })
    sign_in_as users(:one)

    get edit_trade_goods_url

    assert_select 'input[name="campaign[trade_good_base_prices][11]"][value="99000"]'
  end

  test 'update stores a base price override' do
    sign_in_as users(:one)

    patch trade_goods_url, params: { campaign: { trade_good_base_prices: { '11' => '99000' } } }

    assert_redirected_to edit_trade_goods_url
    @campaign.reload

    assert_equal 99_000, TradeGoodPrices.base_price_for(11, @campaign)
  end

  test 'update ignores keys outside the priceable list' do
    sign_in_as users(:one)

    patch trade_goods_url, params: { campaign: { trade_good_base_prices: { '66' => '1', '999' => '2' } } }

    @campaign.reload

    refute @campaign.trade_good_base_prices.key?('66')
    refute @campaign.trade_good_base_prices.key?('999')
  end
end
