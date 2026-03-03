class AuthenticatedIntegrationTest < ActionDispatch::IntegrationTest
  setup { sign_in_as users(:one) }
end
