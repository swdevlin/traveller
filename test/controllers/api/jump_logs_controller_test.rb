# frozen_string_literal: true

require 'test_helper'

class Api::JumpLogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  # GET /api/jumps — no authentication required

  test 'index returns jump logs without authentication' do
    get api_jumps_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    assert response.parsed_body.is_a?(Array)
  end

  # POST /api/jumps — requires session or token

  test 'create with valid bearer token creates jump log' do
    assert_difference 'JumpLog.count', 1 do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id:        ships(:one).id,
             from_parsec_id: parsecs(:one).id,
             to_parsec_id:   parsecs(:two).id,
             depart_year: 1105, depart_day: 100,
             arrive_year: 1105, arrive_day: 107
           } },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :created
  end

  test 'create with active session creates jump log' do
    sign_in_as users(:one)
    assert_difference 'JumpLog.count', 1 do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id:        ships(:one).id,
             from_parsec_id: parsecs(:one).id,
             to_parsec_id:   parsecs(:two).id,
             depart_year: 1105, depart_day: 100,
             arrive_year: 1105, arrive_day: 107
           } },
           as: :json
    end
    assert_response :created
  end

  test 'create without credentials returns unauthorised' do
    assert_no_difference 'JumpLog.count' do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id:        ships(:one).id,
             from_parsec_id: parsecs(:one).id,
             to_parsec_id:   parsecs(:two).id,
             depart_year: 1105, depart_day: 100,
             arrive_year: 1105, arrive_day: 107
           } },
           as: :json
    end
    assert_response :unauthorized
  end

  test 'create with wrong token returns unauthorised' do
    assert_no_difference 'JumpLog.count' do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id:        ships(:one).id,
             from_parsec_id: parsecs(:one).id,
             to_parsec_id:   parsecs(:two).id,
             depart_year: 1105, depart_day: 100,
             arrive_year: 1105, arrive_day: 107
           } },
           headers: { 'Authorization' => 'Bearer wrong-token' },
           as: :json
    end
    assert_response :unauthorized
  end

  test 'create with missing required fields returns unprocessable entity' do
    assert_no_difference 'JumpLog.count' do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: { ship_id: ships(:one).id } },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end
end
