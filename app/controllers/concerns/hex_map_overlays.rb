# frozen_string_literal: true

module HexMapOverlays
  extend ActiveSupport::Concern

  private

  # Survey overlays are a referee-only tool — unauthenticated/public map
  # viewers (e.g. anonymous token-based sector links) get none at all.
  def build_survey_overlays_data
    @enabled_survey_overlays = authenticated? ? SurveyOverlay.ordered.where(enabled: true).to_a : []
  end
end
