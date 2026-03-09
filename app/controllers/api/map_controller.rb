class Api::MapController < ApplicationController
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

    fill_rows = Region
      .joins(region_components: { region_parsecs: :parsec })
      .where(region_parsecs: { kind: 'fill' }, parsecs: { id: viewport_parsec_ids })
      .pluck('parsecs.x', 'parsecs.y', 'regions.colour')

    @fills_by_pos = {}
    fill_rows.each do |px, py, colour|
      col = px - ulx + 1
      row = uly - py + 1
      (@fills_by_pos[[col, row]] ||= []) << { colour: colour }
    end

    label_rows = Region
      .where.not(label: [nil, ''])
      .where.not(label_x: nil)
      .joins(region_components: :region_parsecs)
      .where(region_parsecs: { parsec_id: viewport_parsec_ids })
      .distinct
      .pluck(:label, :label_x, :label_y, :label_colour)

    @region_labels = label_rows.filter_map do |text, lx, ly, label_colour|
      col = lx - ulx + 1
      row = uly - ly + 1
      next unless (1..@cols).include?(col) && (1..@rows).include?(row)

      { col: col, row: row, text: text, colour: label_colour.presence || '#000000' }
    end

    jump_pairs = JumpLog
      .where(from_parsec_id: viewport_parsec_ids)
      .or(JumpLog.where(to_parsec_id: viewport_parsec_ids))
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

    cache_key = "api_map/#{ulx}/#{uly}/#{lrx}/#{lry}/#{parsec_max}-#{system_max}-#{region_max}-#{jump_max}"

    fresh_when etag: cache_key
    return if performed?

    svg = Rails.cache.fetch(cache_key) { render_to_string('api/map/show', formats: [:svg], layout: false) }
    send_data svg, type: 'image/svg+xml', disposition: 'inline'
  end
end
