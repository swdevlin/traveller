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
end
