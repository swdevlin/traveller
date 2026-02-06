# frozen_string_literal: true

class CreateSubsectorJob < ApplicationJob
  queue_as :default

  def perform(sector, letter, x, y, subsector_name = nil)
    subsector = sector.subsectors.create!(
      x: x,
      y: y,
      abbreviation: letter,
      name: subsector_name || letter
    )

    create_parsecs(sector, subsector)

    if sector.source == 'traveller_map'
      import_from_traveller_map(sector, subsector, letter)
    end

    ActionCable.server.broadcast(
      'ui_updates',
      { event: 'subsector_created', sector_id: sector.id, subsector_id: subsector.id }
    )
  end

  private

  def create_parsecs(sector, subsector)
    ul = subsector.universal_coordinates.first
    (0...8).each do |x|
      (0...10).each do |y|
        sector.parsecs.create!(
          x: ul.x + x,
          y: ul.y - y
        )
      end
    end
  end

  def import_from_traveller_map(sector, subsector, letter)
    traveller_map = TravellerMap.new

    # Fetch star systems and convert to build plan
    systems = traveller_map.fetch_subsector_systems(sector.x, sector.y, letter)
    if systems.present?
      build_plan = systems_to_build_plan(systems)
      subsector.update!(build: build_plan)
    end
  end

  def systems_to_build_plan(systems)
    {
      'type' => 'STANDARD',
      'systems' => systems.map(&method(:build_system_definition))
    }.to_yaml
  end

  def parse_stars(stars)
    return [] if stars.blank?

    tokens = stars.split(/\s+/)

    tokens.each_slice(2).filter_map do |type, klass|
      next if type.nil? || klass.nil?
      { 'type' => type, 'class' => klass }
    end
  end

  def ensure_allegiance(allegiance)
    code = allegiance.presence
    return nil if code.nil?

    Allegiance.find_or_create_by!(code: code) do |a|
      a.name = code
    end

    code
  end

  def build_system_definition(sys)
    hex = sys['Hex']
    # Convert sector hex (e.g., "0101") to subsector hex (1-8, 1-10)
    x = ((hex[0, 2].to_i - 1) % 8) + 1
    y = ((hex[2, 2].to_i - 1) % 10) + 1

    entry = { 'x' => x, 'y' => y }
    entry['name'] = sys['Name']
    entry['counts'] = {
      'mainWorld' => {
        'uwp' => sys['UWP'],
        'orbit' => 'hzco',
        'name' => sys['Name']
      },
      'terrestrialPlanets' => sys['PBG'][0].to_i,
      'planetoidBelts' => sys['PBG'][1].to_i,
      'gasGiants' => sys['PBG'][2].to_i
    }

    entry['bases'] = []
    if sys['Bases'].present?
      entry['bases'] = sys['Bases'].split(//)
    end

    entry['allegiance'] = ensure_allegiance(sys['Allegiance'])

    stars = parse_stars(sys['Stars'])

    entry['primary'] = stars.first
    case stars.length
    when 2
      entry['primary']['near'] = stars[1]
    when 3
      entry['primary']['near'] = stars[1]
      entry['primary']['far'] = stars[2]
    when 4..9
      entry['primary']['close'] = stars[1]
      entry['primary']['near'] = stars[2]
      entry['primary']['far'] = stars[3]
    end

    entry
  end
end
