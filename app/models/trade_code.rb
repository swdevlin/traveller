class TradeCode < ApplicationRecord
  validates :code, presence: true, uniqueness: true
  validates :definition, presence: true
end
