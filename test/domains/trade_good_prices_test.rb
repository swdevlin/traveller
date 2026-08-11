# frozen_string_literal: true

require 'test_helper'

class TradeGoodPricesTest < ActiveSupport::TestCase
  test 'returns the sourcebook default when campaign is nil' do
    assert_equal 20_000, TradeGoodPrices.base_price_for(11, nil)
  end

  test 'returns the sourcebook default for a campaign with no override' do
    campaign = campaigns(:one)

    assert_equal 20_000, TradeGoodPrices.base_price_for(11, campaign)
  end

  test 'campaign override takes precedence over the default' do
    campaign = campaigns(:one)
    campaign.trade_good_base_prices = { '11' => '99000' }

    assert_equal 99_000, TradeGoodPrices.base_price_for(11, campaign)
  end

  test 'a blank override falls back to the default' do
    campaign = campaigns(:one)
    campaign.trade_good_base_prices = { '11' => '' }

    assert_equal 20_000, TradeGoodPrices.base_price_for(11, campaign)
  end

  test 'Exotics has no price, override or not' do
    campaign = campaigns(:one)

    assert_nil TradeGoodPrices.base_price_for(66, campaign)
    assert_nil TradeGoodPrices.base_price_for(66, nil)
  end
end
