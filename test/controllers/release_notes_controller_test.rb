require 'test_helper'

class ReleaseNotesControllerTest < ActionDispatch::IntegrationTest
  test 'deltas page is available without logging in' do
    get '/deltas'
    assert_response :success
  end
end
