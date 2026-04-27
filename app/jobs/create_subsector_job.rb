# frozen_string_literal: true

class CreateSubsectorJob < ApplicationJob
  queue_as :default

  def perform(sector_id, letter, x, y, subsector_name = nil)
    sector = Sector.find(sector_id)

    subsector = sector.subsectors.create!(
      x: x,
      y: y,
      abbreviation: letter,
      name: subsector_name || letter
    )

    create_parsecs(sector, subsector)

    if sector.source == 'traveller_map'
      import_from_traveller_map(sector, subsector, letter)
    elsif sector.source == 'deepnight'
      subsector.load_deepnight_defaults!
      subsector.save!
    end

    ActionCable.server.broadcast(
      'ui_updates',
      { event: 'subsector_created', sector_id: sector.id, subsector_id: subsector.id }
    )
  rescue StandardError => e
    Rails.logger.error(
      [
        '[CreateSubsectorJob] failed',
        "sector_id=#{sector&.id}",
        "letter=#{letter.inspect} x=#{x.inspect} y=#{y.inspect}",
        "subsector_name=#{subsector_name.inspect}",
        "error=#{e.class}: #{e.message}",
        e.backtrace&.join("\n")
      ].compact.join("\n")
    )

    raise
  end

  private

  def create_parsecs(sector, subsector)
    ul = subsector.universal_coordinates.first
    now = Time.current
    records = (0...8).flat_map do |x|
      (0...10).map do |y|
        wx = ul.x + x
        wy = ul.y - y
        q = wx
        r = -wy - ((wx - (wx & 1)) / 2)
        s = -q - r
        { sector_id: sector.id, x: wx, y: wy, q: q, r: r, s: s, created_at: now, updated_at: now }
      end
    end
    Parsec.insert_all!(records)
  end

  def import_from_traveller_map(sector, subsector, letter)
    traveller_map = TravellerMap.new
    systems = traveller_map.fetch_subsector_systems(sector.x, sector.y, letter)
    return if systems.empty?

    traveller_map.ensure_allegiances(systems)
    traveller_map.ensure_travel_zones(systems)
    subsector.update!(build: traveller_map.systems_to_build_plan(systems))
  end
end
