ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

require_relative '../db/seed_data/trade_codes'

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  dupes = TRADE_CODES.group_by { |h| h[:code] }.select { |_k, v| v.size > 1 }.keys
  raise "Duplicate trade codes in TRADE_CODES: #{dupes.join(', ')}" if dupes.any?

  fixtures :all
end
