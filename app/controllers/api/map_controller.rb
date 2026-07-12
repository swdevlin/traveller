class Api::MapController < ApplicationController
  include HexMapBases
  include HexMapRogueObjects
  include HexMapOverlays
  def show
    ulx = params[:ulx].to_i
    uly = params[:uly].to_i
    lrx = params[:lrx].to_i
    lry = params[:lry].to_i

    @cols = lrx - ulx + 1
    @rows = uly - lry + 1

    viewport_parsecs = Parsec.includes(:sector)
                             .where(x: ulx..lrx, y: lry..uly)
                             .load

    viewport_parsec_ids = viewport_parsecs.map(&:id)

    star_systems = StarSystem.where(parsec_id: viewport_parsec_ids)
                             .includes(:allegiance, stars: [])
                             .load

    systems_by_parsec_id = star_systems.index_by(&:parsec_id)

    @parsecs_by_pos = {}
    @systems_by_pos = {}

    viewport_parsecs.each do |parsec|
      col = parsec.x - ulx + 1
      row = uly - parsec.y + 1
      @parsecs_by_pos[[col, row]] = {
        id:           parsec.id,
        hex_code:     parsec.hex_code,
        label:        parsec.label,
        label_colour: parsec.label_colour
      }
      sys = systems_by_parsec_id[parsec.id]
      @systems_by_pos[[col, row]] = sys if sys
    end

    @ul = Coordinate.new(ulx, uly)

    @region_fills_by_pos, @region_labels, @region_borders = helpers.regions_for_map(
      viewport_parsecs,
      @ul,
      visible_col: 1..@cols,
      visible_row: 1..@rows,
      authenticated: true
    )

    viewport_parsec_subquery = Parsec.where(x: ulx..lrx, y: lry..uly).select(:id)
    jump_pairs = JumpLog
      .where(from_parsec_id: viewport_parsec_subquery)
      .or(JumpLog.where(to_parsec_id: viewport_parsec_subquery))
      .pluck(:from_parsec_id, :to_parsec_id)

    jump_ids = jump_pairs.flatten.to_set & viewport_parsec_ids.to_set

    @jump_highlight_positions = Set.new
    viewport_parsecs.each do |parsec|
      next unless jump_ids.include?(parsec.id)

      col = parsec.x - ulx + 1
      row = uly - parsec.y + 1
      @jump_highlight_positions << [col, row]
    end

    parsec_max = viewport_parsecs.map(&:updated_at).compact.max&.to_i || 0
    system_max = star_systems.map(&:updated_at).compact.max&.to_i || 0
    region_max = RegionParsec.where(parsec_id: viewport_parsec_ids).maximum(:updated_at)&.to_i || 0
    jump_max   = JumpLog.maximum(:updated_at)&.to_i || 0
    rogue_max  = StellarObject
      .where(parsec_id: viewport_parsec_ids, orbiting_id: nil)
      .where(type: %w[GasGiant Comet])
      .maximum(:updated_at)&.to_i || 0
    rogue_object_max = StellarObject
      .where(parsec_id: viewport_parsec_ids, orbiting_id: nil)
      .where.not(type: %w[GasGiant Comet Star])
      .maximum(:updated_at)&.to_i || 0
    facility_max = StarSystemFacility
      .where(star_system_id: star_systems.map(&:id))
      .maximum(:updated_at)&.to_i || 0

    build_survey_overlays_data

    version = Digest::SHA256.hexdigest([
      parsec_max, system_max, region_max, jump_max, rogue_max, rogue_object_max, facility_max,
      current_campaign.updated_at.to_i, SurveyOverlay.maximum(:updated_at).to_i, SurveyOverlay.count,
      MAP_TEMPLATE_VERSION
    ].join('-'))
    cache_key = "api_map/#{current_campaign.id}/#{ulx}/#{uly}/#{lrx}/#{lry}/#{version}"

    fresh_when etag: cache_key
    return if performed?

    build_bases_data
    build_rogue_objects_data(viewport_parsec_subquery)
    parsec_id_to_pos = @parsecs_by_pos.each_with_object({}) { |(pos, data), h| h[data[:id]] = pos }
    rogue_data = StellarObject
      .where(parsec_id: viewport_parsec_ids, orbiting_id: nil)
      .where(type: %w[GasGiant Comet])
      .pluck(:parsec_id, :type)
    @rogues_by_pos = rogue_data.each_with_object({}) do |(pid, t), h|
      pos = parsec_id_to_pos[pid]
      next unless pos
      h[pos] ||= Set.new
      h[pos] << t
    end.transform_values do |types|
      ordered = []
      ordered << :gas_giant if types.include?('GasGiant')
      ordered << :comet     if types.include?('Comet')
      ordered
    end

    svg = Rails.cache.fetch(cache_key) { render_to_string('shared/hex_map', formats: [:svg], layout: false) }
    send_data svg, type: 'image/svg+xml', disposition: 'inline'
  end
end
