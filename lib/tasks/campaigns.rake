# frozen_string_literal: true

namespace :campaigns do
  desc 'Delete one or all campaigns and their tenant schemas. Use SLUG=foo or ALL=true'
  task delete: :environment do
    if ENV['ALL'] == 'true'
      campaigns = Campaign.all
    elsif ENV['SLUG'].present?
      campaigns = Campaign.where(slug: ENV['SLUG'])
      abort "No campaign found with slug '#{ENV['SLUG']}'" if campaigns.empty?
    else
      abort 'Specify a campaign with SLUG=foo or delete all with ALL=true'
    end

    campaigns.each do |campaign|
      Apartment::Tenant.drop(campaign.schema_name) rescue nil
      campaign.destroy
      puts "Deleted campaign #{campaign.slug} (#{campaign.schema_name})"
    end
  end
end
