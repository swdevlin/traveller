# frozen_string_literal: true

namespace :maps do
  desc 'Generate the all-sectors map. Use SLUG=foo for a specific campaign, or omit for all.'
  task all_sectors: :environment do
    campaigns = if ENV['SLUG'].present?
      campaign = Campaign.find_by(slug: ENV['SLUG'])
      abort "No campaign found with slug '#{ENV['SLUG']}'" unless campaign
      [campaign]
    else
      Campaign.all.to_a
    end

    campaigns.each do |campaign|
      print "Generating all-sectors map for '#{campaign.slug}'... "
      Apartment::Tenant.switch(campaign.schema_name) do
        path = AllSectorsMapGenerator.new(campaign).call
        puts path ? "saved to #{path}" : 'skipped (no sectors)'
      end
    end
  end
end
