class StarSystemTradeCode < ApplicationRecord
  belongs_to :star_system
  belongs_to :trade_code
end
