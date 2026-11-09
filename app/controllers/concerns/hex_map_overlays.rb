# frozen_string_literal: true

module HexMapOverlays
  extend ActiveSupport::Concern

  private

  # Survey overlays are a referee-only tool — unauthenticated/public map
  # viewers (e.g. anonymous token-based sector links) get none at all.
  def build_survey_overlays_data
    @enabled_survey_overlays = authenticated? ? SurveyOverlay.ordered.where(enabled: true).to_a : []
  end

  # Sets the ivars hex_map.svg.erb uses to draw the jump log: the campaign's display settings and
  # one [from_col, from_row, to_col, to_row] segment per jump. Segments may extend beyond the
  # viewport; the map clips them.
  def build_jump_log_overlay(jump_pairs, ul)
    @jump_log_display = current_campaign.jump_log_display_settings
    @jump_segments = []
    return if jump_pairs.empty? || @jump_log_display[:display] == 'none'

    coords = Parsec.where(id: jump_pairs.flatten.uniq).pluck(:id, :x, :y).to_h { |id, x, y| [id, [x, y]] }
    jump_pairs.each do |from_id, to_id|
      from_x, from_y = coords[from_id]
      to_x, to_y = coords[to_id]
      next if from_x.nil? || to_x.nil?

      @jump_segments << [from_x - ul.x + 1, ul.y - from_y + 1, to_x - ul.x + 1, ul.y - to_y + 1]
    end
    @jump_segments.uniq!
  end
end
