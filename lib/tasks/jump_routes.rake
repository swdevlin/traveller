namespace :jump_routes do
  desc 'Marks all network (imported) jump routes as known to players, across every campaign'
  task backfill_network_known: :environment do
    Campaign.find_each do |campaign|
      Apartment::Tenant.switch("camp#{campaign.id}") do
        updated = JumpRoute.where(route_type: 'network', known: [nil, false]).update_all(known: true)
        puts "#{campaign.slug}: marked #{updated} network route(s) as known"
      end
    end
  end

  task :gas_giant_refuel, [:campaign, :route, :m_drive] => :environment do |_task, args|
    extend ActionView::Helpers::NumberHelper
    extend JumpShadowMath

    campaign = Campaign.find_by!(slug: args[:campaign])
    schema = "camp#{campaign.id}"
    m_drive = args[:m_drive].to_i.clamp(0, 10)
    Apartment::Tenant.switch(schema) do
      jump_route = JumpRoute.find_by!(name: args[:route])
      system_ids = jump_route.jump_route_links
        .pluck(:from_star_system_id, :to_star_system_id)
        .flatten
        .uniq

      systems = StarSystem.where(id: system_ids).index_by(&:id)
      gas_giants_by_system = GasGiant
        .where(star_system_id: system_ids)
        .select { |gas_giant| gas_giant.diameter.present? }
        .group_by(&:star_system_id)

      rows = system_ids.map do |id|
        nearest = gas_giants_by_system[id]&.min_by(&:effective_jump_shadow_km)
        { system: systems[id], gas_giant: nearest }
      end

      with_giant, without_giant = rows.partition { |r| r[:gas_giant] }
      with_giant.each { |r| r[:hours] = flip_burn_travel_time_hours(r[:gas_giant].effective_jump_shadow_km, m_drive) }
      with_giant.sort_by! { |r| r[:hours] || Float::INFINITY }

      puts "#{jump_route.name} - minimum gas giant jump safe time by system (#{m_drive}G m-drive)"
      with_giant.each do |r|
        puts "#{r[:system].name}: #{format_travel_time(r[:hours])} (#{r[:gas_giant].display_name}, #{r[:gas_giant].effective_jump_shadow_km.to_i} km)"
      end
      without_giant.sort_by { |r| r[:system].name }.each do |r|
        puts "#{r[:system].name}: No gas giant"
      end
    end
  end

  task :xboats, [:campaign, :route] => :environment do |_task, args|
    campaign = Campaign.find_by!(slug: args[:campaign])
    schema = "camp#{campaign.id}"
    Apartment::Tenant.switch(schema) do
      jump_route = JumpRoute.find_by!(name: args[:route])
      system_links = jump_route.jump_route_links
        .pluck(:from_star_system_id, :to_star_system_id)
        .flatten
        .tally
      systems = StarSystem
        .where(id: system_links.keys)
        .left_joins(main_world: :trade_codes)
        .group('star_systems.id', 'stellar_objects.id')
        .pluck(
          'star_systems.id',
          Arel.sql("(stellar_objects.data -> 'population' ->> 'code')::integer"),
          Arel.sql('ARRAY_AGG(trade_codes.code)'),
          Arel.sql("stellar_objects.data ->> 'starport_code'")
        )
      tenders = 0
      xboats = 0
      spare_xboats = 0
      tankers = 0
      systems.each do |id, population_code, trade_codes, starport_code|
        links = system_links[id]
        if population_code.nil?
          system = StarSystem.find(id)
           puts "#{system.name} (#{id}) has a nil population"
        end

        jumps_per_day = 1

        xb = jumps_per_day * 7 * links
        spares = links * 2
        tenders += [(links.to_f/4).ceil, 1].max + 1
        spare_xboats += spares
        xboats += xb
        tankers += 1 if %w[E X].include?(starport_code)
      end
      puts "Systems = #{systems.size}"
      puts "X-boats = #{xboats}"
      puts "Spare x-boats = #{spare_xboats}"
      puts "Tenders = #{tenders}"
      puts "Tankers = #{tankers}"
    end
  end

  desc 'Deletes all network jump routes for a campaign and reimports them from TravellerMap'
  task :reimport_network, [:campaign] => :environment do |_task, args|
    campaign = Campaign.find_by!(slug: args[:campaign])
    Apartment::Tenant.switch(campaign.schema_name) do
      deleted = JumpRoute.where(route_type: 'network').destroy_all.size
      puts "Deleted #{deleted} network jump route(s)"

      traveller_map = TravellerMap.new
      Sector.kept.where(source: 'traveller_map').find_each do |sector|
        metadata = traveller_map.fetch_sector_metadata(sector.x, sector.y)
        if metadata.blank?
          puts "#{sector.name}: metadata fetch failed, skipped"
          next
        end

        stats = SectorRouteImporter.new(sector, metadata).call
        puts "#{sector.name}: #{stats}"
      end

      puts "\nDone. #{JumpRoute.where(route_type: 'network').count} network route(s), " \
           "#{JumpRouteLink.count} link(s) total."
    end
  end

  task :max_links, [:campaign, :route] => :environment do |_task, args|
    campaign = Campaign.find_by!(slug: args[:campaign])
    schema = "camp#{campaign.id}"
    Apartment::Tenant.switch(schema) do
      jump_route = JumpRoute.find_by!(name: args[:route])
      system_links = jump_route.jump_route_links
        .pluck(:from_star_system_id, :to_star_system_id)
        .flatten
        .tally

      system_id, link_count = system_links.max_by { | _id, count| count }

      system = StarSystem.find(system_id)

      puts "#{system.name} has #{link_count} links"
    end
  end
end
