# frozen_string_literal: true

class Api::SurveyOverlaysController < Api::BaseController
  before_action :authenticate_user_or_token!
  before_action :set_survey_overlay, only: %i[update destroy move_up move_down]

  # Survey overlays are a referee-only tool — there is no player-visible
  # subset, so every action here requires authentication.
  def index
    survey_overlays = SurveyOverlay.ordered
    render json: survey_overlays.map { |survey_overlay| serialize_survey_overlay(survey_overlay) }
  end

  def create
    survey_overlay = SurveyOverlay.new(survey_overlay_params)

    if survey_overlay.save
      render json: serialize_survey_overlay(survey_overlay), status: :created
    else
      render json: { errors: survey_overlay.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @survey_overlay.update(survey_overlay_params)
      render json: serialize_survey_overlay(@survey_overlay)
    else
      render json: { errors: @survey_overlay.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @survey_overlay.destroy!
    head :no_content
  end

  def move_up
    @survey_overlay.move_up!
    render json: serialize_survey_overlay(@survey_overlay.reload)
  end

  def move_down
    @survey_overlay.move_down!
    render json: serialize_survey_overlay(@survey_overlay.reload)
  end

  private

  def set_survey_overlay
    @survey_overlay = SurveyOverlay.find(params[:id])
  end

  # PATCH only ever updates the fields actually present in the request body —
  # `rule_data` is only included when the caller actually sent it.
  def survey_overlay_params
    attrs = params.permit(:name, :colour, :enabled).to_h
    attrs[:rule_data] = rule_data_param if params.key?(:rule_data)
    attrs
  end

  def rule_data_param
    raw = params[:rule_data]
    raw.respond_to?(:to_unsafe_h) ? raw.to_unsafe_h : (raw || {})
  end

  def serialize_survey_overlay(survey_overlay)
    {
      id:        survey_overlay.id,
      name:      survey_overlay.name,
      colour:    survey_overlay.colour,
      enabled:   survey_overlay.enabled?,
      rule_data: survey_overlay.rule_data,
      position:  survey_overlay.position
    }
  end
end
