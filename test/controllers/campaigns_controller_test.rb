require 'test_helper'

class CampaignsControllerTest < ActionDispatch::IntegrationTest
  test 'new does not show the background-tasks job-count widget (no campaign exists yet)' do
    sign_in_as users(:one)

    get new_campaign_url

    assert_response :success
    assert_select "[data-controller='job-count']", count: 0
  end
end
