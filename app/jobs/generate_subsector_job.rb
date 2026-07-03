require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class GenerateSubsectorJob < ApplicationJob
  queue_as :default
  self.log_arguments = false

  def perform(subsector_id, definition)
    subsector = Subsector.find(subsector_id)
    config =
      YAML.safe_load(
        definition,
        permitted_classes: [Date, Time], # add more if you truly need them
        aliases: false
      ) || {}

    config = config.deep_symbolize_keys if config.respond_to?(:deep_symbolize_keys)
    %i[exclude required systems rogues].each do |key|
      value = config[key]

      next unless value.is_a?(Array)

      config.delete(key) if value.compact.empty?
    end

    campaign = Campaign.find_by(schema_name: Apartment::Tenant.current)
    default = campaign&.charted_space? ? 'none' : 'standard'
    config[:sophontCheck] ||= campaign&.sophont_check.presence || default
    config[:maxTechLevel] ||= campaign&.max_tech_level_value || 16
    config[:nativeTechLevel] = campaign&.native_tech_level? || false if config[:nativeTechLevel].nil?
    config[:allowCaptiveGovernment] = campaign.allow_captive_government? if config[:allowCaptiveGovernment].nil? && campaign
    config[:realisticStarDistribution] = campaign.realistic_star_distribution? if config[:realisticStarDistribution].nil? && campaign

    # The external generator knows nothing about rogues; pull them out of the
    # payload and create them locally after the systems are imported.
    rogue_entries = Array(config.delete(:rogues)).compact
    ((config[:systems] || []) + (config[:required] || [])).each do |entry|
      Array(entry.delete(:rogues)).compact.each do |rogue|
        rogue_entries << rogue.merge(x: entry[:x], y: entry[:y])
      end
    end

    SubsectorChannel.broadcast_to(subsector, { event: 'populating' })
    Subsector.transaction do
      subsector.clear(exclude_locked: true)
    end

    base = Rails.application.config.x.generator_service
    uri  = URI.join(base.end_with?('/') ? base : "#{base}/", 'subsector')

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 50
    http.read_timeout = 600
    campaign_id = Campaign.find_by(schema_name: Apartment::Tenant.current)&.id
    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json',
      'x-tenant-id' => campaign_id.to_s
    }

    response = http.post(uri.request_uri, config.to_json, headers)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}" and return
    end

    systems =
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}" and return
      end

    # Build lookups from the original input systems (generator does not echo these back)
    all_input_systems = (config[:systems] || []) + (config[:required] || [])
    zone_by_xy = all_input_systems.each_with_object({}) do |entry, h|
      code = entry[:travelZone].presence
      h[[entry[:x], entry[:y]]] = code if code
    end
    bases_by_xy = all_input_systems.each_with_object({}) do |entry, h|
      codes = entry[:bases].presence
      h[[entry[:x], entry[:y]]] = codes if codes
    end
    subsector_language = config[:language].presence || subsector.effective_language(campaign)
    name_by_xy = all_input_systems.each_with_object({}) do |entry, h|
      h[[entry[:x], entry[:y]]] = entry[:name].presence
    end
    language_by_xy = all_input_systems.each_with_object({}) do |entry, h|
      lang = entry[:language].presence
      h[[entry[:x], entry[:y]]] = lang if lang
    end
    main_world_language_by_xy = all_input_systems.each_with_object({}) do |entry, h|
      lang = entry.dig(:counts, :mainWorld, :language).presence
      lang ||= entry[:primary]&.fetch(:bodies, [])
                               &.find { |b| b[:mainWorld] }
                               &.fetch(:language, nil).presence
      h[[entry[:x], entry[:y]]] = lang if lang
    end

    importer = StarSystemImporter.new
    ul, = subsector.universal_coordinates

    systems.each do |s|
      begin
        parsec = Parsec.find_by(x: ul.x + s['x']-1, y: ul.y - (s['y'] - 1))
        next if parsec.nil?
        next if parsec.star_systems.locked.exists?

        star_system = importer.import!(
          parsec, s,
          campaign: campaign,
          subsector_language: subsector_language,
          system_language: language_by_xy[[s['x'], s['y']]],
          main_world_language: main_world_language_by_xy[[s['x'], s['y']]],
          system_name: name_by_xy[[s['x'], s['y']]]
        )

        zone_code = zone_by_xy[[s['x'], s['y']]]
        if zone_code && (tz = TravelZone.find_by(code: zone_code))
          star_system.update_column(:travel_zone_id, tz.id)
        end

        base_codes = bases_by_xy[[s['x'], s['y']]]
        if base_codes
          Facility.where(code: base_codes).each do |facility|
            StarSystemFacility.find_or_create_by!(star_system: star_system, facility: facility)
          end
        end
      rescue StandardError => e
        Rails.logger.error "#{uri} Error importing system #{s['name']}: #{e.message}"
      end
    end

    rogue_builder = RogueObjectBuilder.new(generator_service: GeneratorService.new(campaign_id: campaign_id))
    rogue_entries.each do |entry|
      parsec = Parsec.find_by(x: ul.x + entry[:x] - 1, y: ul.y - (entry[:y] - 1))
      next if parsec.nil?
      next if parsec.star_systems.locked.exists?

      rogue_builder.build!(parsec, entry)
    rescue StandardError => e
      Rails.logger.error "Error creating rogue #{entry[:type]} at #{entry[:x]},#{entry[:y]}: #{e.message}"
    end

    import_jump_routes(subsector.sector) if subsector.sector.source == 'traveller_map'

    SubsectorChannel.broadcast_to(subsector, { event: 'finished' })
    ActionCable.server.broadcast(
      'ui_updates',
      { event: 'subsector_populated', sector_id: subsector.sector_id, subsector_id: subsector.id }
    )
  end

  private

  def import_jump_routes(sector)
    metadata = Rails.cache.fetch(['travellermap_sector_metadata', sector.x, sector.y], expires_in: 15.minutes) do
      TravellerMap.new.fetch_sector_metadata(sector.x, sector.y)
    end
    return if metadata.blank?

    SectorRouteImporter.new(sector, metadata).call
  rescue StandardError => e
    Rails.logger.error "Jump route import failed for sector #{sector.id}: #{e.message}"
  end
end
