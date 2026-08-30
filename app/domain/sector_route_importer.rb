# frozen_string_literal: true

class SectorRouteImporter
  DEFAULT_ALLEGIANCE_CODE = 'Im'

  def initialize(sector, metadata)
    @sector = sector
    @routes = Array(metadata.is_a?(Hash) ? metadata['Routes'] : nil)
  end

  def call
    stats = { entries_total: @routes.size, links_created: 0, links_skipped_existing: 0, entries_skipped_unresolved: 0 }

    @routes.each do |route|
      from_system = resolve_star_system(route['Start'], route['StartOffsetX'], route['StartOffsetY'])
      to_system   = resolve_star_system(route['End'], route['EndOffsetX'], route['EndOffsetY'])

      if from_system.nil? || to_system.nil? || from_system.id == to_system.id
        stats[:entries_skipped_unresolved] += 1
        next
      end

      jump_route = find_or_create_jump_route(route['Allegiance'])
      low_id, high_id = [from_system.id, to_system.id].sort

      if JumpRouteLink.exists?(from_star_system_id: low_id, to_star_system_id: high_id)
        stats[:links_skipped_existing] += 1
      else
        JumpRouteLink.create!(jump_route: jump_route, from_star_system_id: low_id, to_star_system_id: high_id)
        stats[:links_created] += 1
      end
    end

    stats
  end

  private

  def resolve_star_system(hex, offset_x, offset_y)
    return nil if hex.blank?

    target_sector = resolve_sector(offset_x.to_i, offset_y.to_i)
    return nil if target_sector.nil?

    ul = target_sector.upper_left
    x = ul.x + (hex[0, 2].to_i - 1)
    y = ul.y - (hex[2, 2].to_i - 1)

    parsec = (@parsec_cache ||= {}).fetch([target_sector.id, x, y]) do
      @parsec_cache[[target_sector.id, x, y]] = Parsec.find_by(sector_id: target_sector.id, x: x, y: y)
    end

    parsec&.star_systems&.first
  end

  def resolve_sector(offset_x, offset_y)
    return @sector if offset_x.zero? && offset_y.zero?

    (@sector_cache ||= {}).fetch([offset_x, offset_y]) do
      @sector_cache[[offset_x, offset_y]] = Sector.kept.find_by(x: @sector.x + offset_x, y: @sector.y - offset_y)
    end
  end

  def find_or_create_jump_route(allegiance)
    code = allegiance.presence || DEFAULT_ALLEGIANCE_CODE

    (@jump_route_cache ||= {}).fetch(code) do
      @jump_route_cache[code] = JumpRoute.find_or_create_by!(travellermap_allegiance_code: code) do |jump_route|
        jump_route.name = "#{code} Jump Route"
        jump_route.route_type = 'network'
        jump_route.colour = '#6b7280'
        jump_route.known = true
      end
    end
  end
end
