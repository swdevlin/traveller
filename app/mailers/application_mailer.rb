class ApplicationMailer < ActionMailer::Base
  default from: Rails.application.credentials.dig(:smtp, :from) || 'noreply@example.com'
  layout 'mailer'
end
