require 'test_helper'

class ApplicationControllerTest < ActionDispatch::IntegrationTest
  test 'visiting a nonexistent campaign slug redirects to root without looping' do
    get '/c/does-not-exist/sectors'

    assert_redirected_to '/'
    follow_redirect!
    assert_response :success
  end
end
