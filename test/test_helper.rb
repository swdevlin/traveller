ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'webmock/minitest'

# Parallel worker databases are created via a direct Ruby call to load_schema,
# bypassing rake hooks. Patch it here so shared_extensions is always created
# before schema.rb is loaded, in every database including worker databases.
module EnsureSharedExtensionsSchema
  def load_schema(db_config, format = ActiveRecord.schema_format, file = nil)
    ActiveRecord::Base.establish_connection(db_config)
    ActiveRecord::Base.connection.execute('CREATE SCHEMA IF NOT EXISTS shared_extensions')
    ActiveRecord::Base.connection.execute('CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA shared_extensions')
  rescue StandardError
    # schema/extension may already exist or not be needed — proceed regardless
  ensure
    super
  end
end
ActiveRecord::Tasks::DatabaseTasks.singleton_class.prepend(EnsureSharedExtensionsSchema)

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
