Rails.application.config.x.generator_service = ENV.fetch('GENERATOR_SERVICE_URL', 'http://host.docker.internal:3007')
