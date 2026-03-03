ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

require_relative '../db/seed_data/trade_codes'
require_relative 'test_helpers/session_test_helper'
require_relative 'test_helpers/authenticated_integration_test'

WebMock.disable_net_connect!(allow_localhost: true)

class ActiveSupport::TestCase
  parallelize(workers: :number_of_processors)

  dupes = TRADE_CODES.group_by { |h| h[:code] }.select { |_k, v| v.size > 1 }.keys
  raise "Duplicate trade codes in TRADE_CODES: #{dupes.join(', ')}" if dupes.any?

  fixtures :all
end
