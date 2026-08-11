# frozen_string_literal: true

module TradeGoodsHelper
  def trade_good_category_label(category)
    { common: 'Common', trade: 'Trade', illegal: 'Illegal', exotic: 'Exotic' }.fetch(category.to_sym, category.to_s)
  end

  def trade_availability_label(availability)
    availability == :all ? 'All' : availability.join(' ')
  end
end
