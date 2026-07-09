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

  test 'create sets survey_index to 10 for star systems in destination parsec' do
    system_in_dest = star_systems(:in_two)
    system_in_dest.update!(survey_index: 3)

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

    assert_response :created
    assert_equal 10, system_in_dest.reload.survey_index
  end

  test 'create does not lower survey_index already above 10 in destination parsec' do
    system_in_dest = star_systems(:in_two)
    system_in_dest.update!(survey_index: 11)
    original_updated_at = system_in_dest.updated_at

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

    assert_response :created
    system_in_dest.reload
    assert_equal 11, system_in_dest.survey_index
    assert_equal original_updated_at, system_in_dest.updated_at
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
