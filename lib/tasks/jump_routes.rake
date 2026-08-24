namespace :jump_routes do
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
        .joins(main_world: :trade_codes)
        .group('star_systems.id', 'stellar_objects.id')
        .pluck(
          'star_systems.id',
          Arel.sql("(stellar_objects.data -> 'population' ->> 'code')::integer"),
          Arel.sql('ARRAY_AGG(trade_codes.code)')
        )
      tenders = 0
      xboats = 0
      spare_xboats = 0
      systems.each do |id, population_code, trade_codes|
        links = system_links[id]
        if population_code.nil?
          system = StarSystem.find(id)
           puts "#{system.name} (#{id}) has a nil population"
        end

        if population_code > 8 or 'Cp' in trade_codes or 'Cs' in trade_codes 
          jumps_per_day = 3
        else
          jumps_per_day = 1
        end
        xb = jumps_per_day * links
        spares = [population_code.to_i * links, 2].max
        tenders += [(xb.to_f/4).ceil,1].max
        spare_xboats += spares
        xboats += xb
      end
      puts "Systems = #{systems.size}"
      puts "X-boats = #{xboats}"
      puts "Spare x-boats = #{spare_xboats}"
      puts "Tenders = #{tenders}"
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
