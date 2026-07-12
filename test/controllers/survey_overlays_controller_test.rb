require 'test_helper'

class SurveyOverlaysControllerTest < AuthenticatedIntegrationTest
  setup do
    @survey_overlay = survey_overlays(:one)
  end

  test 'should get index' do
    get survey_overlays_url
    assert_response :success
  end

  test 'should get new' do
    get new_survey_overlay_url
    assert_response :success
  end

  test 'should create survey overlay' do
    assert_difference('SurveyOverlay.count') do
      post survey_overlays_url,
           params: { survey_overlay: { name: 'New Survey Overlay', colour: '#123456', enabled: true } }
    end

    assert_redirected_to survey_overlay_url(SurveyOverlay.last)
  end

  test 'should reject creating a survey overlay with invalid rule data json' do
    assert_no_difference('SurveyOverlay.count') do
      post survey_overlays_url,
           params: { survey_overlay: { name: 'New Survey Overlay', colour: '#123456', rule_data_json: 'not json' } }
    end

    assert_response :unprocessable_entity
  end

  test 'should show survey overlay' do
    get survey_overlay_url(@survey_overlay)
    assert_response :success
  end

  test 'should get edit' do
    get edit_survey_overlay_url(@survey_overlay)
    assert_response :success
  end

  test 'should update survey overlay' do
    patch survey_overlay_url(@survey_overlay), params: { survey_overlay: { name: 'Renamed', colour: @survey_overlay.colour } }

    assert_redirected_to survey_overlay_url(@survey_overlay)
    assert_equal 'Renamed', @survey_overlay.reload.name
  end

  test 'patching only name leaves existing rule data untouched' do
    @survey_overlay.update!(
      rule_data: { groups: [[{ field: 'starport', operator: 'eq', negate: false, values: ['A'] }]] }
    )

    patch survey_overlay_url(@survey_overlay), params: { survey_overlay: { name: 'Renamed' } }

    assert_redirected_to survey_overlay_url(@survey_overlay)
    @survey_overlay.reload
    assert_equal 'Renamed', @survey_overlay.name
    assert_equal 1, @survey_overlay.groups.size
  end

  test 'should destroy survey overlay' do
    assert_difference('SurveyOverlay.count', -1) do
      delete survey_overlay_url(@survey_overlay)
    end

    assert_redirected_to survey_overlays_url
  end

  test 'move_up swaps position with the previous survey overlay' do
    other = survey_overlays(:two)
    survey_overlay_position = @survey_overlay.position
    other_position = other.position

    patch move_up_survey_overlay_url(other)

    assert_redirected_to survey_overlays_url
    assert_equal other_position, @survey_overlay.reload.position
    assert_equal survey_overlay_position, other.reload.position
  end

  test 'move_down swaps position with the next survey overlay' do
    other = survey_overlays(:two)
    survey_overlay_position = @survey_overlay.position
    other_position = other.position

    patch move_down_survey_overlay_url(@survey_overlay)

    assert_redirected_to survey_overlays_url
    assert_equal other_position, @survey_overlay.reload.position
    assert_equal survey_overlay_position, other.reload.position
  end
end
