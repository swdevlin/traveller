# frozen_string_literal: true

# Renders the "move to another hex" modal for a star system or rogue: a hex map
# (the same one the jump route link modal uses) whose hexes are click targets,
# plus a sector/hex address form for destinations off the map.
module HexMoveModal
  extend ActiveSupport::Concern

  include HexViewport

  MOVE_RADII = (2..6).to_a.freeze
  DEFAULT_MOVE_RADIUS = 4

  private

  def render_move_modal(record, move_path:, modal_path:, label:)
    @record = record
    @move_label = label
    @move_path = move_path
    @modal_path = modal_path
    @radius = MOVE_RADII.include?(params[:radius].to_i) ? params[:radius].to_i : DEFAULT_MOVE_RADIUS
    @return_to = local_return_path

    parsec = record.parsec
    viewport_parsecs, star_systems = build_hex_viewport(parsec, @radius)
    occupied = star_systems.map(&:parsec_id).to_set

    @hex_move_urls = {}
    @parsecs_by_pos.each do |pos, data|
      next if data[:id] == parsec.id
      next if record.is_a?(StarSystem) && occupied.include?(data[:id])

      @hex_move_urls[pos] = {
        url: "#{move_path}?#{{ parsec_id: data[:id], return_to: @return_to }.compact.to_query}",
        confirm: "Move #{label} to #{data[:hex_code]}?"
      }
    end

    build_survey_overlays_data
    @map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)
    @sector = parsec.sector
    @hex_code = parsec.hex_code
    @sectors = Sector.kept.order(:name).to_a

    render 'application/move_modal', layout: false
  end
end
