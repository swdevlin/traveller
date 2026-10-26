class StellarObjectTradeCode < ApplicationRecord
  belongs_to :stellar_object
  belongs_to :trade_code

  # Pass a precomputed trade_code_lookup (code => id) when assigning for many objects to
  # avoid re-reading the trade codes table each time.
  def self.assign_from_codes!(stellar_object, codes, trade_code_lookup: nil)
    return if codes.blank?

    trade_code_lookup ||= TradeCode.pluck(:code, :id).to_h
    records = GeneratorMappings.trade_code_records_for(stellar_object.id, codes, trade_code_lookup, Time.current)
    insert_all(records) if records.any?
  end
end
