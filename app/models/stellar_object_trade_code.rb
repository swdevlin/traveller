class StellarObjectTradeCode < ApplicationRecord
  belongs_to :stellar_object
  belongs_to :trade_code
end
