# frozen_string_literal: true

namespace :star_systems do
  desc 'Reassign orbit sequences for a star system. Use CAMPAIGN=slug ID=123'
  task :assign_orbit_sequences, [:campaign, :id] => :environment do |_task, args|
    slug = (args[:campaign] || ENV['CAMPAIGN']).presence or abort 'Specify a campaign with CAMPAIGN=slug'
    id = (args[:id] || ENV['ID']).presence or abort 'Specify a star system with ID=123'
    campaign = Campaign.find_by(slug: slug) or abort "No campaign found with slug '#{slug}'"

    Apartment::Tenant.switch(campaign.schema_name) do
      star_system = StarSystem.find_by(id: id) or abort "No star system with id #{id} in campaign '#{slug}'"

      OrbitSequenceAssigner.new(star_system).assign!
      puts "Reassigned orbit sequences for #{star_system.display_name}"
    end
  end
end
