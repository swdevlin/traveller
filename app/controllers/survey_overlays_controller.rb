# frozen_string_literal: true

class SurveyOverlaysController < ApplicationController
  before_action :set_survey_overlay, except: %i[index new create]
  rescue_from JSON::ParserError, with: :render_invalid_rule_data

  def index
    @survey_overlays = SurveyOverlay.ordered
  end

  def show
  end

  def new
    @survey_overlay = SurveyOverlay.new
  end

  def edit
  end

  def create
    @survey_overlay = SurveyOverlay.new(survey_overlay_params)

    if @survey_overlay.save
      redirect_to @survey_overlay, notice: 'Survey overlay created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @survey_overlay.update(survey_overlay_params)
      redirect_to @survey_overlay, notice: 'Survey overlay updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @survey_overlay.destroy!
    redirect_to survey_overlays_path, notice: 'Survey overlay deleted.', status: :see_other
  end

  def move_up
    @survey_overlay.move_up!
    redirect_to survey_overlays_path, status: :see_other
  end

  def move_down
    @survey_overlay.move_down!
    redirect_to survey_overlays_path, status: :see_other
  end

  private

  def set_survey_overlay
    @survey_overlay = SurveyOverlay.find(params.expect(:id))
  end

  # PATCH only ever updates the fields actually present in the request —
  # `rule_data_json` is included only by the full rule editor.
  def survey_overlay_params
    attrs = params.expect(survey_overlay: %i[name colour enabled])
    attrs[:rule_data] = rule_data_param if rule_data_json_submitted?
    attrs
  end

  def rule_data_json_submitted?
    params[:survey_overlay]&.key?(:rule_data_json)
  end

  def rule_data_param
    JSON.parse(params.dig(:survey_overlay, :rule_data_json).presence || '{}')
  end

  def render_invalid_rule_data
    flash.now[:alert] = 'Rule data was not valid JSON.'
    @survey_overlay ||= SurveyOverlay.new
    @survey_overlay.errors.add(:rule_data, 'must be valid JSON')
    render(@survey_overlay.persisted? ? :edit : :new, status: :unprocessable_entity)
  end
end
