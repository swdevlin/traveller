Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins '*'
    resource '/c/*/api/*', headers: :any, methods: %i[get post patch put delete options]
  end
end
