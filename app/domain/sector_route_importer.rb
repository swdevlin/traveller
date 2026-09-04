# frozen_string_literal: true

class SectorRouteImporter
  DEFAULT_ALLEGIANCE_CODE = 'Im'
  LOCAL_TRADE_CODE = 'LocalTrade'

  # Known X-boat tender hops that stay on the Imperium's Express Boat network regardless of
  # local allegiance or route Type. Each entry is [sector_name, system_name, sector_name, system_name].
  FORCED_IM_LINKS = [
    ['The Beyond', 'Delta Base', 'The Beyond', 'Aacheon'],
    ['The Beyond', 'Aacheon', 'The Beyond', 'Tellus'],
    ['The Beyond', 'Tellus', 'The Beyond', 'Web Edge'],
    ['The Beyond', 'Web Edge', 'The Beyond', 'Aakumaska'],
    ['The Beyond', 'Aakumaska', 'The Beyond', 'Dedeged'],
    ['The Beyond', 'Dedeged', 'The Beyond', 'Cirat'],
    ['The Beyond', 'Cirat', 'The Beyond', 'Morphy'],
    ['The Beyond', 'Morphy', 'The Beyond', 'Alekhine'],
    ['The Beyond', 'Alekhine', 'The Beyond', 'Midway'],
    ['The Beyond', 'Midway', 'The Beyond', 'Kazar'],
    ['The Beyond', 'Kazar', 'Spinward Marches', 'Raweh'],
    ['The Beyond', 'Morphy', 'The Beyond', 'Djend'],
    ['The Beyond', 'Djend', 'The Beyond', 'Tartakover'],
    ['Spinward Marches', 'Caladbolg', 'Spinward Marches', 'Biter'],
    ['Spinward Marches', 'Biter', 'Spinward Marches', 'Adabicci']
  ].freeze

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

      jump_route = find_or_create_jump_route(route['Allegiance'], route['Type'], from_system, to_system)
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

  def find_or_create_jump_route(allegiance, type, from_system, to_system)
    route_code = resolve_route_code(allegiance, type, from_system, to_system)

    (@jump_route_cache ||= {}).fetch(route_code) do
      @jump_route_cache[route_code] = JumpRoute.find_or_create_by!(travellermap_allegiance_code: route_code) do |jump_route|
        jump_route.name = route_name_for(route_code)
        jump_route.route_type = 'network'
        jump_route.colour = '#6b7280'
        jump_route.known = true
      end
    end
  end

  def resolve_route_code(allegiance, type, from_system, to_system)
    return DEFAULT_ALLEGIANCE_CODE if forced_im_link?(from_system, to_system)

    trade = type == 'Trade'
    code = allegiance.presence || common_endpoint_allegiance_code(from_system, to_system)

    if code.blank?
      return trade ? LOCAL_TRADE_CODE : DEFAULT_ALLEGIANCE_CODE
    end

    code = DEFAULT_ALLEGIANCE_CODE if code.start_with?('Im')
    trade ? "#{code}-Trade" : code
  end

  def route_name_for(route_code)
    return 'Express Boat' if route_code == DEFAULT_ALLEGIANCE_CODE
    return 'Local Trade Route' if route_code == LOCAL_TRADE_CODE
    return "#{route_code.delete_suffix('-Trade')} Trade Route" if route_code.end_with?('-Trade')

    "#{route_code} Jump Route"
  end

  def common_endpoint_allegiance_code(from_system, to_system)
    from_code = from_system.allegiance&.code
    to_code = to_system.allegiance&.code
    from_code if from_code.present? && from_code == to_code
  end

  def forced_im_link?(from_system, to_system)
    a = [from_system.parsec.sector.name, from_system.name]
    b = [to_system.parsec.sector.name, to_system.name]
    FORCED_IM_LINKS.any? { |s1, n1, s2, n2| (a == [s1, n1] && b == [s2, n2]) || (a == [s2, n2] && b == [s1, n1]) }
  end
end
