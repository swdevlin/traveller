class AuthenticatedIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    sign_in_as users(:one)
    self.default_url_options = { campaign_slug: campaigns(:one).slug }
  end
end
