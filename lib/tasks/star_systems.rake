include ActionView::Helpers::NumberHelper

namespace :star_systems do
  task :gwp, [:campaign, :allegiance] => :environment do |_task, args|
    campaign = Campaign.find_by!(slug: args[:campaign])
    schema = "camp#{campaign.id}"
    Apartment::Tenant.switch(schema) do
      systems = StarSystem
        .joins(:allegiance, :main_world)
        .where('allegiances.code ILIKE ?', "%#{args[:allegiance]}%")
        .pluck(
          Arel.sql("(stellar_objects.data -> 'economics' ->> 'totalGWP')::float")
        )
      puts "Systems = #{systems.size}"
      total_gwp = systems.compact.sum
      puts "Total GWP = #{number_to_human(total_gwp)}"
      puts "No GWP = #{systems.count(nil)}"
    end
  end

  desc 'Top 5 main worlds by effective jump shadow (safe jump distance), optionally with M-drive travel time'
  task :top_jump_distance, [:campaign, :m_drive] => :environment do |_task, args|
    extend JumpShadowMath
    campaign = Campaign.find_by!(slug: args[:campaign])
    schema = "camp#{campaign.id}"
    m_drive = args[:m_drive].presence&.to_i

    Apartment::Tenant.switch(schema) do
      top = []

      StarSystem.joins(:main_world).includes(main_world: :orbiting, parsec: :sector).find_each do |system|
        km = system.main_world.effective_jump_shadow_km
        next if top.size >= 5 && km <= top.last[1]

        top << [system, km]
        top = top.sort_by { |(_, k)| -k }.first(5)
      end

      top.each do |system, km|
        location = "#{system.parsec.sector.name} #{system.parsec.hex_code}"
        line = "#{system.display_name} (#{location}) — #{number_to_human(km)} km"
        line += " — #{format_travel_time(flip_burn_travel_time_hours(km, m_drive))} at #{m_drive}G" if m_drive

        puts line
      end
    end
  end
end
