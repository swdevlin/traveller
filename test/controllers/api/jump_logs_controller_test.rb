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

  # index payload

  test 'index includes ship name and omits notes for the public' do
    get api_jumps_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    row = response.parsed_body.first
    assert row.key?('ship_name')
    assert row.key?('sequence')
    assert_not row.key?('notes')
  end

  test 'index includes notes for the referee' do
    sign_in_as users(:one)
    get api_jumps_url(campaign_slug: @campaign.slug), as: :json
    assert_response :success
    assert response.parsed_body.first.key?('notes')
  end

  # PATCH /api/jumps/:id — requires session or token

  test 'update with active session updates jump log' do
    sign_in_as users(:one)
    jump = jump_logs(:one)
    patch api_jump_url(campaign_slug: @campaign.slug, id: jump.id),
          params: { jump_log: { notes: 'Edited', misjump: true } },
          as: :json
    assert_response :success
    assert_equal 'Edited', jump.reload.notes
    assert jump.misjump?
  end

  test 'update with valid bearer token updates jump log' do
    jump = jump_logs(:one)
    patch api_jump_url(campaign_slug: @campaign.slug, id: jump.id),
          params: { jump_log: { notes: 'Via token' } },
          headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
          as: :json
    assert_response :success
    assert_equal 'Via token', jump.reload.notes
  end

  test 'update without credentials returns unauthorised' do
    jump = jump_logs(:one)
    patch api_jump_url(campaign_slug: @campaign.slug, id: jump.id),
          params: { jump_log: { notes: 'Nope' } },
          as: :json
    assert_response :unauthorized
    assert_not_equal 'Nope', jump.reload.notes
  end

  test 'update with invalid data returns unprocessable entity' do
    sign_in_as users(:one)
    jump = jump_logs(:one)
    patch api_jump_url(campaign_slug: @campaign.slug, id: jump.id),
          params: { jump_log: { ship_id: nil } },
          as: :json
    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end

  # DELETE /api/jumps/:id — requires session or token, a ship's most recent jump only

  test 'destroy removes the most recent jump of a ship with an active session' do
    sign_in_as users(:one)
    assert_difference 'JumpLog.count', -1 do
      delete api_jump_url(campaign_slug: @campaign.slug, id: jump_logs(:chain_c).id), as: :json
    end
    assert_response :no_content
  end

  test 'destroy removes the most recent jump of a ship that is not the most recent overall' do
    sign_in_as users(:one)
    # Ship two's only jump is dated before ship one's later jumps.
    assert_difference 'JumpLog.count', -1 do
      delete api_jump_url(campaign_slug: @campaign.slug, id: jump_logs(:two).id), as: :json
    end
    assert_response :no_content
  end

  test 'destroy refuses a jump that is not its ship\'s most recent' do
    sign_in_as users(:one)
    assert_no_difference 'JumpLog.count' do
      delete api_jump_url(campaign_slug: @campaign.slug, id: jump_logs(:chain_a).id), as: :json
    end
    assert_response :unprocessable_entity
    assert response.parsed_body.key?('errors')
  end

  test 'destroy without credentials returns unauthorised' do
    assert_no_difference 'JumpLog.count' do
      delete api_jump_url(campaign_slug: @campaign.slug, id: jump_logs(:chain_c).id), as: :json
    end
    assert_response :unauthorized
  end

  # Editing a jump's arrival shifts the later jumps of the same ship

  test 'update shifts later jumps of the same ship when arrival changes' do
    sign_in_as users(:one)
    first = jump_logs(:chain_a)
    later = jump_logs(:chain_b)
    patch api_jump_url(campaign_slug: @campaign.slug, id: first.id),
          params: { jump_log: { arrive_day: first.arrive_day + 2 } },
          as: :json
    assert_response :success
    assert_equal later.depart_day + 2, later.reload.depart_day
  end

  # Date rules

  test 'create with too short a travel time returns unprocessable entity' do
    assert_no_difference 'JumpLog.count' do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id: ships(:one).id, from_parsec_id: parsecs(:one).id, to_parsec_id: parsecs(:two).id,
             depart_year: 1105, depart_day: 100, arrive_year: 1105, arrive_day: 105
           } },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :unprocessable_entity
    assert_match(/6 days/, response.parsed_body['errors'].join)
  end

  test 'create of a misjump allows any arrival date' do
    assert_difference 'JumpLog.count', 1 do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id: ships(:one).id, from_parsec_id: parsecs(:one).id, to_parsec_id: parsecs(:two).id,
             depart_year: 1105, depart_day: 100, arrive_year: 1105, arrive_day: 100, misjump: true
           } },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :created
  end

  test 'create departing before the ships previous arrival returns unprocessable entity' do
    assert_no_difference 'JumpLog.count' do
      post api_jumps_url(campaign_slug: @campaign.slug),
           params: { jump_log: {
             ship_id: ships(:one).id, from_parsec_id: parsecs(:one).id, to_parsec_id: parsecs(:two).id,
             depart_year: 1105, depart_day: 10, arrive_year: 1105, arrive_day: 30
           } },
           headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
           as: :json
    end
    assert_response :unprocessable_entity
    assert_match(/previous arrival/, response.parsed_body['errors'].join)
  end

  test 'create raises the survey index of an empty destination parsec' do
    dest = parsecs(:two)
    StarSystem.where(parsec_id: dest.id).delete_all
    dest.update!(survey_index: 2)

    post api_jumps_url(campaign_slug: @campaign.slug),
         params: { jump_log: {
           ship_id: ships(:one).id, from_parsec_id: parsecs(:one).id, to_parsec_id: dest.id,
           depart_year: 1105, depart_day: 100, arrive_year: 1105, arrive_day: 107
         } },
         headers: { 'Authorization' => "Bearer #{@campaign.api_token}" },
         as: :json

    assert_response :created
    assert_equal 10, dest.reload.survey_index
  end

  test 'update raises the survey index of the new destination' do
    sign_in_as users(:one)
    system = star_systems(:in_two)
    system.update!(survey_index: 3)
    jump = jump_logs(:chain_c)

    patch api_jump_url(campaign_slug: @campaign.slug, id: jump.id),
          params: { jump_log: { to_parsec_id: system.parsec_id } },
          as: :json

    assert_response :success
    assert_equal 10, system.reload.survey_index
  end
end
