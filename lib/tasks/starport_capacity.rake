# frozen_string_literal: true

namespace :starport_capacity do
  # Main worlds can also be gas giants, which have no UWP or starport.
  STARPORT_CAPACITY_TYPES = %w[TerrestrialPlanet PlanetoidBelt Planetoid Moon].freeze
  STARPORT_CAPACITY_RETRIES = 3
  STARPORT_CAPACITY_NETWORK_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError
  ].freeze

  desc 'Backfill starport capacity on main worlds that have none. The generator rolls dice, so each world is ' \
       'called once and worlds that already have data are skipped. Optionally pass SLUG=my-slug to target one campaign, ' \
       'or FORCE=1 to re-roll and overwrite worlds that already have data.'
  task backfill: :environment do
    campaigns = ENV['SLUG'].present? ? Campaign.where(slug: ENV['SLUG']) : Campaign.all
    abort "No campaign found with slug '#{ENV['SLUG']}'" if campaigns.empty?

    force = ENV['FORCE'].present?
    puts 'FORCE: re-rolling and overwriting existing starport capacity' if force
    totals = Hash.new(0)

    campaigns.each.with_index(1) do |campaign, campaign_index|
      Apartment::Tenant.switch(campaign.schema_name) do
        service = GeneratorService.new(campaign_id: campaign.id)
        worlds = StellarObject
                 .where(type: STARPORT_CAPACITY_TYPES)
                 .where(id: StarSystem.where.not(main_world_id: nil).select(:main_world_id))
                 .includes(:trade_codes)
        worlds = worlds.where("data->>'starport_capacity' IS NULL") unless force

        total = worlds.count
        counts = Hash.new(0)
        missing = Hash.new { |hash, field| hash[field] = [] }
        puts "[#{campaign_index}/#{campaigns.size}] Backfilling '#{campaign.slug}' (#{total} worlds)"
        worlds.find_each.with_index(1) do |world, index|
          result = starport_capacity_for(world, service, missing)
          counts[result] += 1
          totals[result] += 1
          puts "  #{index}/#{total}" if (index % 100).zero?
        end
        puts "  '#{campaign.slug}': #{counts[:updated]} updated, #{counts[:skipped]} skipped, #{counts[:failed]} failed"
        missing.each do |field, ids|
          puts "    missing #{field}: #{ids.size} worlds (e.g. #{ids.first(5).join(', ')})"
        end
      end
    end

    puts "Starport capacity: #{totals[:updated]} updated, #{totals[:skipped]} skipped, #{totals[:failed]} failed"
  end

  # Returns :updated, :skipped or :failed.
  def starport_capacity_for(world, service, missing)
    return :skipped if world.no_population?

    payload = starport_capacity_payload(world)
    absent = payload.select { |_key, value| value.nil? }.keys
    if absent.any?
      absent.each { |field| missing[field] << world.id }
      return :failed
    end

    result = starport_capacity_request(service, payload, world)
    if result.nil? || !result.success?
      puts "  FAILED #{world.id}: #{result ? result.errors.join('; ') : 'network error'}"
      return :failed
    end
    return :skipped if result.value.blank?

    world.update_columns(data: (world.data || {}).merge('starport_capacity' => result.value))
    :updated
  end

  def starport_capacity_payload(world)
    {
      starPort: world.starport_code,
      populationCode: world.population_code,
      censusPopulation: world.population&.dig('censusPopulation') || starport_capacity_midpoint_population(world),
      importance: world.importance,
      efficiency: world.efficiency,
      infrastructure: world.infrastructure,
      techLevel: world.tech_level_code,
      industrial: world.trade_codes.any? { it.code == 'In' }
    }
  end

  # Worlds generated before censusPopulation existed: use the middle of the UWP population code's range.
  # The range table stops at 12; beyond that the pattern continues (code n spans 10^n to 10^(n+1) - 1).
  def starport_capacity_midpoint_population(world)
    code = world.population_code.to_i
    range = StellarObjectsHelper::POPULATION_RANGES[code]
    if range
      low, high = range.scan(/[\d,]+/).map { it.delete(',').to_i }
    elsif code > 12
      low = 10**code
      high = (10**(code + 1)) - 1
    else
      return nil
    end
    (low + high) / 2
  end

  def starport_capacity_request(service, payload, world)
    attempts = 0
    begin
      attempts += 1
      service.starport_capacity(payload)
    rescue *STARPORT_CAPACITY_NETWORK_ERRORS => e
      if attempts < STARPORT_CAPACITY_RETRIES
        sleep(2**attempts)
        retry
      end
      Rails.logger.error "starport_capacity world #{world.id}: #{e.class} #{e.message}"
      nil
    end
  end
end
