# frozen_string_literal: true

namespace :starport_capacity do
  STARPORT_CAPACITY_RETRIES = 3
  STARPORT_CAPACITY_NETWORK_ERRORS = [
    Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET, EOFError
  ].freeze

  desc 'Backfill starport capacity on main worlds that have none. The generator rolls dice, so each world is ' \
       'called once and worlds that already have data are skipped. Optionally pass SLUG=my-slug to target one campaign.'
  task backfill: :environment do
    campaigns = ENV['SLUG'].present? ? Campaign.where(slug: ENV['SLUG']) : Campaign.all
    abort "No campaign found with slug '#{ENV['SLUG']}'" if campaigns.empty?

    totals = Hash.new(0)

    campaigns.each.with_index(1) do |campaign, campaign_index|
      Apartment::Tenant.switch(campaign.schema_name) do
        service = GeneratorService.new(campaign_id: campaign.id)
        worlds = StellarObject
                 .where(id: StarSystem.where.not(main_world_id: nil).select(:main_world_id))
                 .where("data IS NULL OR NOT jsonb_exists(data, 'starport_capacity')")
                 .includes(:trade_codes)

        total = worlds.count
        counts = Hash.new(0)
        puts "[#{campaign_index}/#{campaigns.size}] Backfilling '#{campaign.slug}' (#{total} worlds)"
        worlds.find_each.with_index(1) do |world, index|
          result = starport_capacity_for(world, service)
          counts[result] += 1
          totals[result] += 1
          puts "  #{index}/#{total}" if (index % 100).zero?
        end
        puts "  '#{campaign.slug}': #{counts[:updated]} updated, #{counts[:skipped]} skipped, #{counts[:failed]} failed"
      end
    end

    puts "Starport capacity: #{totals[:updated]} updated, #{totals[:skipped]} skipped, #{totals[:failed]} failed"
  end

  # Returns :updated, :skipped or :failed.
  def starport_capacity_for(world, service)
    return :skipped if world.no_population?

    payload = starport_capacity_payload(world)
    missing = payload.select { |_key, value| value.nil? }.keys
    if missing.any?
      puts "  FAILED #{world.id}: missing #{missing.join(', ')}"
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
      censusPopulation: world.population&.dig('censusPopulation'),
      importance: world.importance,
      efficiency: world.efficiency,
      infrastructure: world.infrastructure,
      techLevel: world.tech_level_code,
      industrial: world.trade_codes.any? { it.code == 'In' }
    }
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
