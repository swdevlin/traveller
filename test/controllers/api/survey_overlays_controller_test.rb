# frozen_string_literal: true

require 'test_helper'

class Api::SurveyOverlaysControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
  end

  test 'index without credentials returns unauthorised' do
    SurveyOverlay.create!(name: 'Referee Overlay', colour: '#112233')

    get api_survey_overlays_url(campaign_slug: @campaign.slug), as: :json

    assert_response :unauthorized
  end

  test 'index returns survey overlays for an authenticated session' do
    survey_overlay = SurveyOverlay.create!(name: 'Referee Overlay', colour: '#112233')
    sign_in_as users(:one)

    get api_survey_overlays_url(campaign_slug: @campaign.slug), as: :json

    assert_response :success
    body = response.parsed_body
    ids = body.map { |o| o['id'] }
    assert_includes ids, survey_overlay.id

    entry = body.find { |o| o['id'] == survey_overlay.id }
    assert_equal 'Referee Overlay', entry['name']
    assert_equal '#112233', entry['colour']
  end

  test 'index returns survey overlays for a valid bearer token' do
    survey_overlay = SurveyOverlay.create!(name: 'Referee Overlay', colour: '#112233')

    get api_survey_overlays_url(campaign_slug: @campaign.slug),
        headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :success
    ids = response.parsed_body.map { |o| o['id'] }
    assert_includes ids, survey_overlay.id
  end

  test 'create without credentials returns unauthorised and creates nothing' do
    assert_no_difference -> { SurveyOverlay.count } do
      post api_survey_overlays_url(campaign_slug: @campaign.slug),
           params: { name: 'New Overlay', colour: '#112233' }, as: :json
    end
    assert_response :unauthorized
  end

  test 'create with active session succeeds' do
    sign_in_as users(:one)

    assert_difference -> { SurveyOverlay.count }, 1 do
      post api_survey_overlays_url(campaign_slug: @campaign.slug),
           params: {
             name: 'New Overlay', colour: '#112233',
             rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: ['A'] }]] }
           }, as: :json
    end

    assert_response :created
    survey_overlay = SurveyOverlay.order(:created_at).last
    assert_equal 'New Overlay', survey_overlay.name
  end

  test 'create rejects invalid rule data' do
    sign_in_as users(:one)

    assert_no_difference -> { SurveyOverlay.count } do
      post api_survey_overlays_url(campaign_slug: @campaign.slug),
           params: { name: 'New Overlay', colour: '#112233',
                     rule_data: { groups: [[{ field: 'nope', operator: 'eq', negate: false, values: ['A'] }]] } },
           as: :json
    end

    assert_response :unprocessable_entity
  end

  test 'update without credentials returns unauthorised' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    patch api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id),
          params: { name: 'Renamed' }, as: :json

    assert_response :unauthorized
    assert_equal 'Overlay', survey_overlay.reload.name
  end

  test 'update with active session changes permitted fields' do
    sign_in_as users(:one)
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#000000')

    patch api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id),
          params: { name: 'Renamed', colour: '#ffffff' }, as: :json

    assert_response :success
    survey_overlay.reload
    assert_equal 'Renamed', survey_overlay.name
    assert_equal '#ffffff', survey_overlay.colour
  end

  test 'update without a rule_data key leaves existing rule data untouched' do
    sign_in_as users(:one)
    survey_overlay = SurveyOverlay.create!(
      name: 'Overlay', colour: '#000000',
      rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: ['A'] }]] }
    )

    patch api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id),
          params: { enabled: false }, as: :json

    assert_response :success
    survey_overlay.reload
    assert_not survey_overlay.enabled?
    assert_equal 1, survey_overlay.groups.size
  end

  test 'update with valid bearer token succeeds' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#000000')

    patch api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id),
          params: { name: 'Renamed' },
          headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :success
    assert_equal 'Renamed', survey_overlay.reload.name
  end

  test 'destroy without credentials returns unauthorised and destroys nothing' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    assert_no_difference -> { SurveyOverlay.count } do
      delete api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id), as: :json
    end
    assert_response :unauthorized
  end

  test 'destroy with active session succeeds' do
    sign_in_as users(:one)
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    assert_difference -> { SurveyOverlay.count }, -1 do
      delete api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id), as: :json
    end
    assert_response :no_content
  end

  test 'destroy with valid bearer token succeeds' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    assert_difference -> { SurveyOverlay.count }, -1 do
      delete api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id),
             headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json
    end
    assert_response :no_content
  end

  test 'move_up without credentials returns unauthorised' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    patch move_up_api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id), as: :json

    assert_response :unauthorized
  end

  test 'move_up and move_down swap position with the adjacent survey overlay' do
    sign_in_as users(:one)
    first = SurveyOverlay.create!(name: 'First', colour: '#111111')
    second = SurveyOverlay.create!(name: 'Second', colour: '#222222')
    first_position = first.position
    second_position = second.position

    patch move_up_api_survey_overlay_url(campaign_slug: @campaign.slug, id: second.id), as: :json

    assert_response :success
    assert_equal second_position, first.reload.position
    assert_equal first_position, second.reload.position

    patch move_down_api_survey_overlay_url(campaign_slug: @campaign.slug, id: second.id), as: :json

    assert_response :success
    assert_equal first_position, first.reload.position
    assert_equal second_position, second.reload.position
  end
end
