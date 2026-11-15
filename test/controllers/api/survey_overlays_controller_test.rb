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

  test 'another campaign referee cannot see tag criteria or modify overlays' do
    overlay = SurveyOverlay.create!(name: 'Private tags', colour: '#123456',
      rule_data: { groups: [[{ field: 'tags', operator: 'has', values: ['Private tag'] }]] })
    sign_in_as users(:two)
    get api_survey_overlays_url(campaign_slug: @campaign.slug), as: :json
    assert_response :forbidden
    assert_not_includes response.body, 'Private tag'
    delete api_survey_overlay_url(overlay, campaign_slug: @campaign.slug), as: :json
    assert_response :forbidden
    assert SurveyOverlay.exists?(overlay.id)
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

  test 'update with a position without credentials returns unauthorised' do
    survey_overlay = SurveyOverlay.create!(name: 'Overlay', colour: '#112233')

    patch api_survey_overlay_url(campaign_slug: @campaign.slug, id: survey_overlay.id), params: { position: 1 }, as: :json

    assert_response :unauthorized
  end

  test 'create stores a condition without negate as not negated' do
    post api_survey_overlays_url(campaign_slug: @campaign.slug),
         params: { name: 'Port overlay', colour: '#112233',
                   rule_data: { groups: [[{ field: 'starport', operator: 'eq', values: ['A'] }]] } },
         headers: { 'Authorization' => "Bearer #{@campaign.api_token}" }, as: :json

    assert_response :created
    assert_equal false, response.parsed_body.dig('rule_data', 'groups', 0, 0, 'negate')
  end

  def token_headers
    { 'Authorization' => "Bearer #{@campaign.api_token}" }
  end

  def three_overlays
    SurveyOverlay.destroy_all
    %w[A B C].map { |name| SurveyOverlay.create!(name: name, colour: '#112233') }
  end

  test 'update with a position moves the overlay in one call' do
    _, _, c = three_overlays

    patch api_survey_overlay_url(c, campaign_slug: @campaign.slug),
          params: { position: 1 }, headers: token_headers, as: :json

    assert_response :success
    assert_equal 1, response.parsed_body['position']
    assert_equal %w[C A B], SurveyOverlay.ordered.pluck(:name)
  end

  test 'update can rename and move together' do
    a, = three_overlays

    patch api_survey_overlay_url(a, campaign_slug: @campaign.slug),
          params: { name: 'Renamed', position: 3 }, headers: token_headers, as: :json

    assert_response :success
    assert_equal %w[B C Renamed], SurveyOverlay.ordered.pluck(:name)
  end

  test 'update without a position leaves the order alone' do
    a, = three_overlays

    patch api_survey_overlay_url(a, campaign_slug: @campaign.slug),
          params: { name: 'Renamed' }, headers: token_headers, as: :json

    assert_response :success
    assert_equal %w[Renamed B C], SurveyOverlay.ordered.pluck(:name)
  end

  test 'update rejects a position outside the list' do
    a, = three_overlays

    [0, -1, 4].each do |position|
      patch api_survey_overlay_url(a, campaign_slug: @campaign.slug),
            params: { position: position }, headers: token_headers, as: :json

      assert_response :unprocessable_entity, "position #{position}"
      assert_equal ['Position must be a whole number between 1 and 3'], response.parsed_body['errors']
    end
    assert_equal %w[A B C], SurveyOverlay.ordered.pluck(:name)
  end

  test 'update rejects a position that is not a whole number' do
    a, = three_overlays

    ['two', '1.5', ''].each do |position|
      patch api_survey_overlay_url(a, campaign_slug: @campaign.slug),
            params: { position: position }, headers: token_headers, as: :json

      assert_response :unprocessable_entity, "position #{position.inspect}"
    end
  end

  test 'a rejected position does not apply the other changes' do
    a, = three_overlays

    patch api_survey_overlay_url(a, campaign_slug: @campaign.slug),
          params: { name: 'Renamed', position: 0 }, headers: token_headers, as: :json

    assert_response :unprocessable_entity
    assert_equal 'A', a.reload.name
  end

  test 'create without a position adds the overlay to the end of the list' do
    three_overlays

    post api_survey_overlays_url(campaign_slug: @campaign.slug),
         params: { name: 'D', colour: '#445566' }, headers: token_headers, as: :json

    assert_response :created
    assert_equal 4, response.parsed_body['position']
    assert_equal %w[A B C D], SurveyOverlay.ordered.pluck(:name)
  end
end
