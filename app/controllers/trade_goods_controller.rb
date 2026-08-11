# frozen_string_literal: true

class TradeGoodsController < ApplicationController
  def edit
    @rows = TradeGoodsTable.all.reject { |row| row[:base_price].nil? }.map do |row|
      price = TradeGoodPrices.base_price_for(row[:d66], current_campaign)
      row.merge(price: price, price_step: 10**[price.to_s.length - 2, 0].max)
    end
  end

  def update
    current_campaign.update!(trade_goods_params)
    redirect_to edit_trade_goods_path, notice: 'Trade good prices updated.', status: :see_other
  end

  private

  def trade_goods_params
    params.expect(campaign: [{ trade_good_base_prices: TradeGoodsTable.priceable_d66_codes.map(&:to_s) }])
  end
end
