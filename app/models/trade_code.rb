class TradeCode < ApplicationRecord
  include TouchesStarSystems

  validates :code, presence: true, uniqueness: true
  validates :definition, presence: true
end
