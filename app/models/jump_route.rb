# frozen_string_literal: true

class JumpRoute < ApplicationRecord
  LINE_STYLES  = %w[solid dashed dotted dash_dot dash_dot_dot long_dash short_dash].freeze
  ROUTE_TYPES  = %w[plotted network].freeze
  REFUELING    = %w[any commercial refined wilderness].freeze

  validates :name,       presence: true
  validates :line_style, inclusion: { in: LINE_STYLES }
  validates :line_width, numericality: { only_integer: true, greater_than: 0 }
  validates :route_type, inclusion: { in: ROUTE_TYPES }

  has_many :jump_route_links, dependent: :destroy
  belongs_to :from_star_system, class_name: 'StarSystem', optional: true
  belongs_to :to_star_system,   class_name: 'StarSystem', optional: true

  SECTOR_COLS = 32
  SECTOR_ROWS = 40

  scope :ordered, -> { order(:name) }

  def plotted? = route_type == 'plotted'
  def network? = route_type == 'network'

  def excluded_travel_zones
    return TravelZone.none if excluded_travel_zone_ids.blank?

    TravelZone.where(id: excluded_travel_zone_ids).ordered
  end

  def ordered_systems
    return [] unless from_star_system_id && to_star_system_id

    pairs = jump_route_links.pluck(:from_star_system_id, :to_star_system_id)
    all_ids = pairs.flatten.uniq
    systems_by_id = StarSystem.where(id: all_ids).includes(:main_world, parsec: :sector).index_by(&:id)

    adjacency = Hash.new { |h, k| h[k] = [] }
    pairs.each { |a, b| adjacency[a] << b; adjacency[b] << a }

    path = [from_star_system_id]
    visited = Set.new([from_star_system_id])

    loop do
      current = path.last
      break if current == to_star_system_id

      next_id = adjacency[current].find { |id| !visited.include?(id) }
      break unless next_id

      visited << next_id
      path << next_id
    end

    return [] unless path.last == to_star_system_id

    path.map { |id| systems_by_id[id] }.compact
  end

  def recalculate_links!
    plan = RoutePlanner.new(
      from_id:                  from_star_system_id,
      to_id:                    to_star_system_id,
      jump_range:               max_jump || 2,
      refueling:                refueling || 'any',
      excluded_travel_zone_ids: excluded_travel_zone_ids || []
    ).plan
    return nil unless plan

    jump_route_links.destroy_all
    plan.hops.each_cons(2) do |a, b|
      JumpRouteLink.create!(
        jump_route:          self,
        from_star_system_id: a.system.id,
        to_star_system_id:   b.system.id
      )
    end
    plan
  end

  def fits_in_sector?
    system_ids = jump_route_links.pluck(:from_star_system_id, :to_star_system_id).flatten.uniq
    return false if system_ids.empty?

    min_x, max_x, min_y, max_y = Parsec
      .joins(:star_systems)
      .where(star_systems: { id: system_ids })
      .pick(Arel.sql('MIN(parsecs.x), MAX(parsecs.x), MIN(parsecs.y), MAX(parsecs.y)'))

    return false if min_x.nil?
    (max_x - min_x + 1) <= SECTOR_COLS && (max_y - min_y + 1) <= SECTOR_ROWS
  end

  def stroke_dasharray
    case line_style
    when 'dashed'       then '16,10'
    when 'dotted'       then '3,7'
    when 'dash_dot'     then '16,7,3,7'
    when 'dash_dot_dot' then '16,7,3,7,3,7'
    when 'long_dash'    then '28,10'
    when 'short_dash'   then '8,7'
    end
  end
end
