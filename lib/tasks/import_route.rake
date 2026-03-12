require 'json'

desc 'Import jump logs from route.json. Usage: rake import_route[slug]'
task :import_route, [:slug] => :environment do |_t, args|
  slug = args[:slug].presence or abort 'Usage: rake import_route[slug]'
  campaign = Campaign.find_by(slug: slug) or abort "Campaign '#{slug}' not found"

  path = Rails.root.join('route.json')
  abort "route.json not found at #{path}" unless path.exist?

  waypoints = JSON.parse(File.read(path))

  Apartment::Tenant.switch(campaign.schema_name) do
    ship     = Ship.find(waypoints.first['ship_id'])
    imported = 0
    skipped  = 0

    waypoints.each_cons(2) do |from_wp, to_wp|
      from_parsec = Parsec.find_by(x: from_wp['origin_x'], y: from_wp['origin_y'])
      to_parsec   = Parsec.find_by(x: to_wp['origin_x'],   y: to_wp['origin_y'])

      unless from_parsec && to_parsec
        missing = []
        missing << "from (#{from_wp['sector_name']} #{from_wp['hex_x'].to_s.rjust(2, '0')}#{from_wp['hex_y'].to_s.rjust(2, '0')})" unless from_parsec
        missing << "to (#{to_wp['sector_name']} #{to_wp['hex_x'].to_s.rjust(2, '0')}#{to_wp['hex_y'].to_s.rjust(2, '0')})"   unless to_parsec
        puts "SKIP: parsec not found — #{missing.join(', ')}"
        skipped += 1
        next
      end

      arrive_year = to_wp['year']
      arrive_day  = to_wp['day']

      if arrive_day > 7
        depart_day  = arrive_day - 7
        depart_year = arrive_year
      else
        depart_day  = 365 + arrive_day - 7
        depart_year = arrive_year - 1
      end

      JumpLog.create!(
        ship:        ship,
        from_parsec: from_parsec,
        to_parsec:   to_parsec,
        depart_year: depart_year,
        depart_day:  depart_day,
        arrive_year: arrive_year,
        arrive_day:  arrive_day
      )

      puts "#{from_parsec.display_name} → #{to_parsec.display_name} " \
           "[#{depart_year}-#{format('%03d', depart_day)} → #{arrive_year}-#{format('%03d', arrive_day)}]"
      imported += 1
    end

    puts "\nDone. Imported: #{imported}, Skipped: #{skipped}"
  end
end
