# frozen_string_literal: true

class CreateSubsectorJob < ApplicationJob
  queue_as :subsector_creation

  # Where the Deepnight Revelation campaign's starting ship is seeded: Demnan,
  # hex 3124 of the Incognita Citerior sector.
  DEMNAN_SECTOR = { x: -10, y: -2 }.freeze
  DEMNAN_SUBSECTOR_LETTER = 'L'
  DEMNAN_HEX = '3124'
  CAMPAIGN_START_YEAR = 1105
  CAMPAIGN_START_DAY = 1

  def perform(sector_id, letter, x, y, subsector_name = nil, default_build_spec = nil, build_source = 'default', populate = false)
    sector = Sector.find(sector_id)
    campaign = Campaign.find_by(schema_name: Apartment::Tenant.current)

    # The new sector form pre-fills each subsector's name with its letter. Treat that as
    # "no name chosen" so a sector language can supply a generated name instead.
    subsector_name = nil if subsector_name == letter

    subsector = sector.subsectors.find_by(x: x, y: y)

    if subsector
      create_parsecs(sector, subsector) unless subsector.parsecs.exists?
    else
      name = if subsector_name.present?
        subsector_name
      elsif sector.source == 'manual' && (effective_lang = sector.effective_language(campaign)).present?
        WordGenerator.new(language: effective_lang.to_sym).generate
      else
        letter
      end

      subsector = sector.subsectors.create!(
        x: x,
        y: y,
        abbreviation: letter,
        name: name
      )

      create_parsecs(sector, subsector)
    end

    if subsector.build.present?
      # A retry after a prior attempt already assigned a build spec — leave it alone.
    elsif sector.source == 'traveller_map'
      import_from_traveller_map(sector, subsector, letter)
    elsif sector.source == 'deepnight'
      subsector.load_deepnight_defaults!
      subsector.save!
    elsif default_build_spec.present?
      subsector.update!(build: default_build_spec, build_source: build_source)
    end

    queue_population(sector, subsector) if populate && subsector.build.present?
    seed_deepnight_starting_ship(campaign, sector, letter, subsector)

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

  def queue_population(sector, subsector)
    priority = sector.x.abs * 1000 + sector.y.abs * 10 + subsector.y + subsector.x
    GenerateSubsectorJob.set(priority: priority).perform_later(subsector.id, subsector.build)
  end

  def seed_deepnight_starting_ship(campaign, sector, letter, subsector)
    return unless campaign&.deepnight_revelation?
    return unless sector.x == DEMNAN_SECTOR[:x] && sector.y == DEMNAN_SECTOR[:y]
    return unless letter == DEMNAN_SUBSECTOR_LETTER
    return if Ship.exists?(name: 'Revelation')

    address = Parsec.new(sector: sector)
    address.hex_code = DEMNAN_HEX
    demnan_parsec = subsector.parsecs.find_by(x: address.x, y: address.y)
    return unless demnan_parsec

    ship = Ship.create!(name: 'Revelation', jump_drive: 4, m_drive: 4)
    JumpLog.create!(
      ship: ship, from_parsec: demnan_parsec, to_parsec: demnan_parsec,
      depart_year: CAMPAIGN_START_YEAR, depart_day: CAMPAIGN_START_DAY,
      arrive_year: CAMPAIGN_START_YEAR, arrive_day: CAMPAIGN_START_DAY
    )
  end

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
    systems = TravellerMap.new.fetch_subsector_systems(sector.x, sector.y, letter)
    return if systems.empty?

    parser = T5TabDelimitedParser.new(systems)
    parser.ensure_allegiances
    parser.ensure_travel_zones
    subsector.update!(build: parser.build_plan)
  end
end
