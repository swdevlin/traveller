# frozen_string_literal: true

class CreateSubsectorJob < ApplicationJob
  queue_as :default

  def perform(sector_id, letter, x, y, subsector_name = nil, default_build_spec = nil, build_source = 'default')
    sector = Sector.find(sector_id)
    campaign = Campaign.find_by(schema_name: Apartment::Tenant.current)

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
    systems = TravellerMap.new.fetch_subsector_systems(sector.x, sector.y, letter)
    return if systems.empty?

    parser = T5TabDelimitedParser.new(systems)
    parser.ensure_allegiances
    parser.ensure_travel_zones
    subsector.update!(build: parser.build_plan)
  end
end
