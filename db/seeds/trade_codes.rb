# frozen_string_literal: true

require_relative '../seed_data/trade_codes'

TradeCode.upsert_all(TRADE_CODES, unique_by: %i[code])
