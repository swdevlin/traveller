# frozen_string_literal: true

class RoutePlanner
  include HexDistance

  SystemNode = Struct.new(:id, :name, :x, :y, :gas_giant_count, :starport_code, :hex_label, :travel_zone_id, :known, :survey_index, keyword_init: true)
  Hop        = Struct.new(:system, :distance, keyword_init: true)
  RoutePlan  = Struct.new(:hops, keyword_init: true)

  STARPORT_COMMERCIAL = %w[A B C D].freeze
  STARPORT_REFINED    = %w[A B].freeze
  ATTRIBUTE_CHECK_REFUELING = %w[commercial refined wilderness].freeze
  KNOWN_SURVEY_INDEX_THRESHOLD = 10

  def initialize(from_id:, to_id:, jump_range:, refueling:, excluded_travel_zone_ids: [], restrict_to_known: false)
    @from_id                  = from_id
    @to_id                    = to_id
    @jump_range               = jump_range
    @refueling                = refueling
    @excluded_travel_zone_ids = Array(excluded_travel_zone_ids).map(&:to_i).uniq
    @restrict_to_known        = restrict_to_known
  end

  # Returns a RoutePlan or nil when no route exists.
  def plan
    nodes     = load_nodes
    pos_map   = nodes.index_by { |n| [n.x, n.y] }
    from_node = nodes.find { |n| n.id == @from_id }
    to_node   = nodes.find { |n| n.id == @to_id }
    return nil unless from_node && to_node

    path = a_star(from_node, to_node, pos_map)
    return nil unless path

    hops = [Hop.new(system: path.first, distance: 0)]
    path.each_cons(2) do |a, b|
      hops << Hop.new(system: b, distance: hex_distance([a.x, a.y], [b.x, b.y]))
    end
    RoutePlan.new(hops: hops)
  end

  def parsec_distance(from_system, to_system)
    hex_distance(
      [from_system.parsec.x, from_system.parsec.y],
      [to_system.parsec.x,   to_system.parsec.y]
    )
  end

  private

  def load_nodes
    sql = <<~SQL
      SELECT ss.id, ss.name, p.x, p.y, ss.gas_giant_count, ss.travel_zone_id, ss.known, ss.survey_index,
             so.data->>'starport_code' AS starport_code,
             sec.name || ' ' ||
               LPAD((p.x - sec.x * 32 + 1)::text, 2, '0') ||
               LPAD((sec.y * 40 - p.y + 1)::text, 2, '0') AS hex_label
      FROM star_systems ss
      JOIN parsecs p ON p.id = ss.parsec_id
      JOIN sectors sec ON sec.id = p.sector_id
      LEFT JOIN stellar_objects so ON so.id = ss.main_world_id
      WHERE sec.discarded_at IS NULL
    SQL

    ActiveRecord::Base.connection.execute(sql).map do |row|
      SystemNode.new(
        id:              row['id'].to_i,
        name:            row['name'],
        x:               row['x'].to_i,
        y:               row['y'].to_i,
        gas_giant_count: row['gas_giant_count'].to_i,
        starport_code:   row['starport_code'],
        hex_label:       row['hex_label'],
        travel_zone_id:  row['travel_zone_id']&.to_i,
        known:           row['known'],
        survey_index:    row['survey_index'].to_i
      )
    end
  end

  # Origin and destination are always eligible; the filter only constrains intermediates.
  def eligible?(node)
    return true if node.id == @from_id || node.id == @to_id
    return false if @excluded_travel_zone_ids.any? && @excluded_travel_zone_ids.include?(node.travel_zone_id)
    return false if @restrict_to_known && requires_attribute_check? && !player_visible?(node)

    case @refueling
    when 'refined'    then STARPORT_REFINED.include?(node.starport_code)
    when 'commercial' then STARPORT_COMMERCIAL.include?(node.starport_code)
    when 'wilderness' then node.gas_giant_count > 0
    else true
    end
  end

  def requires_attribute_check?
    ATTRIBUTE_CHECK_REFUELING.include?(@refueling)
  end

  def player_visible?(node)
    node.known || node.survey_index >= KNOWN_SURVEY_INDEX_THRESHOLD
  end

  def neighbours(node, pos_map)
    y_range = (@jump_range * 1.15).ceil
    results = []
    ((node.x - @jump_range)..(node.x + @jump_range)).each do |nx|
      ((node.y - y_range)..(node.y + y_range)).each do |ny|
        candidate = pos_map[[nx, ny]]
        next unless candidate
        next if candidate.id == node.id
        next unless hex_distance([node.x, node.y], [nx, ny]) <= @jump_range
        results << candidate
      end
    end
    results
  end

  def a_star(from, to, pos_map)
    g         = { from => 0 }
    came_from = {}
    open_set  = [[heuristic(from, to), from]]

    until open_set.empty?
      _, current = open_set.min_by(&:first)
      open_set.reject! { |entry| entry[1].equal?(current) }

      return reconstruct(came_from, current) if current.equal?(to)

      neighbours(current, pos_map).each do |nb|
        next unless eligible?(nb)

        tentative = g[current] + 1
        next if g[nb] && g[nb] <= tentative

        g[nb]         = tentative
        came_from[nb] = current
        open_set << [tentative + heuristic(nb, to), nb]
      end
    end

    nil
  end

  def heuristic(a, b)
    (hex_distance([a.x, a.y], [b.x, b.y]).to_f / @jump_range).ceil
  end

  def reconstruct(came_from, node)
    path = [node]
    path.unshift(node = came_from[node]) while came_from[node]
    path
  end
end
