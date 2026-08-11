# frozen_string_literal: true

# Base Price is the one campaign-overridable value on the Trade Goods table
# (Mongoose Traveller 2e Core Rulebook, p.244-245) — everything else (availability,
# tons dice, DM lists) is fixed sourcebook data, see TradeGoodsTable. Overrides
# live on Campaign#settings as the trade_good_base_prices store_accessor, a Hash
# of "d66" => Integer, edited via TradeGoodsController rather than Campaign Settings.
module TradeGoodPrices
  # @param d66 [Integer]
  # @param campaign [Campaign, nil]
  # @return [Integer, nil] resolved Base Price, campaign override applied over the
  #   sourcebook default — nil for Exotics (66), which has no price.
  def self.base_price_for(d66, campaign)
    default = TradeGoodsTable.for(d66)&.fetch(:base_price)
    return default unless campaign

    override = campaign.trade_good_base_prices&.[](d66.to_s)
    override.presence ? override.to_i : default
  end
end
