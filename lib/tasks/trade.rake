require 'csv'

namespace :trade do
  BTN_HEADERS = [
    'origin sector', 'origin hex', 'origin name', 'origin WTN', 'origin xenophilia DM',
    'partner sector', 'partner hex', 'partner name', 'partner WTN', 'partner xenophilia DM', 'distance',
    'export count', 'export sum', 'import count', 'import sum'
  ].freeze

  desc 'Writes the Bilateral Trade Numbers between every system in a sector and each system within ' \
       'jump range to CSV: trade:btn[campaign_slug,sector_name,output_path,jump]'
  task :btn, [:campaign, :sector, :output, :jump] => :environment do |_task, args|
    campaign = Campaign.find_by!(slug: args[:campaign])
    jump = (args[:jump].presence || 6).to_i
    # Xenophilia (1-17) as a standard Traveller characteristic DM: 0-2 is -2, 3-5 is -1, 6-8 is 0,
    # 9-11 is +1, 12-14 is +2 and 15+ is +3, so a xenophobic world has a negative DM.
    xenophilia = lambda { |system|
      value = system.main_world.try(:population_xenophilia)
      value && (value / 3) - 2
    }
    wtn = ->(system) { system.main_world_wtn&.round(1) }

    Apartment::Tenant.switch(campaign.schema_name) do
      sector = Sector.kept.find_by!('LOWER(name) = ?', args[:sector].to_s.downcase)
      output = args[:output].presence || Rails.root.join('tmp', "btn_#{campaign.slug}_#{sector.name.parameterize}.csv").to_s

      origins = StarSystem.joins(:parsec).where(parsecs: { sector_id: sector.id }).where.not(main_world_id: nil)
                          .includes({ parsec: :sector }, :travel_zone, main_world: :trade_codes)
                          .order('parsecs.x, parsecs.y')
      total = origins.count
      pairs = 0

      CSV.open(output, 'w') do |csv|
        csv << BTN_HEADERS
        origins.find_each.with_index(1) do |origin, index|
          next if wtn.call(origin).nil?

          partners = TradeSynergyCalculator.partners_within(origin, jump).select { wtn.call(it) }
          rows = TradeSynergyCalculator.new(origin: origin, partners: partners).calculate[:partners]
          partners_by_id = partners.index_by(&:id)

          rows.sort_by { [it[:distance], it[:hex]] }.each do |row|
            partner = partners_by_id.fetch(row[:id])
            csv << [
              origin.parsec.sector.name, origin.parsec.hex_code, origin.name, wtn.call(origin), xenophilia.call(origin),
              row[:sector], row[:hex], row[:name], wtn.call(partner), xenophilia.call(partner), row[:distance],
              row[:outbound_count], row[:outbound_bonus], row[:inbound_count], row[:inbound_bonus]
            ]
            pairs += 1
          end
          puts "#{index}/#{total} #{origin.name || origin.parsec.hex_code}: #{rows.size} partners" if (index % 25).zero?
        end
      end

      puts "Wrote #{pairs} rows for #{total} systems in #{sector.name} to #{output}"
    end
  end
end
