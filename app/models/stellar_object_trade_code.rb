class StellarObjectTradeCode < ApplicationRecord
  belongs_to :stellar_object
  belongs_to :trade_code

  def self.assign_from_codes!(stellar_object, codes)
    return if codes.blank?

    codes.uniq.each do |code|
      trade_code = TradeCode.find_by(code: code)
      next unless trade_code

      find_or_create_by!(stellar_object: stellar_object, trade_code: trade_code)
    end
  end
end
