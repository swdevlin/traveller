require_relative 'boot'

require 'rails/all'

require 'apartment/elevators/generic'
require_relative '../app/middleware/campaign_elevator'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Traveller
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    config.middleware.insert_before ActionDispatch::Executor, CampaignElevator

    # Please, add to the `ignore` list any other `lib` subdirectionaries that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.active_record.schema_format = :sql

    config.autoload_lib(ignore: %w[assets tasks])

    config.solid_queue.clear_finished_jobs_after = 1.month

    Rails.autoloaders.main.collapse(Rails.root.join('app/domain/word_generators'))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
