class TradeCode < ApplicationRecord
  has_many :star_system_trade_codes, dependent: :destroy
  has_many :star_systems, through: :star_system_trade_codes

  validates :code, presence: true, uniqueness: true
  validates :definition, presence: true
end
