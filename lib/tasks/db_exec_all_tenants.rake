# frozen_string_literal: true

namespace :db do
  desc 'Run a raw SQL statement against every tenant schema. ' \
       'Usage: SQL="update ..." bin/rails db:exec_all_tenants, ' \
       'or SQL_FILE=path/to.sql bin/rails db:exec_all_tenants. ' \
       'Optionally pass SLUG=my-slug to target one campaign.'
  task exec_all_tenants: :environment do
    sql = ENV['SQL_FILE'].present? ? File.read(ENV['SQL_FILE']) : ENV['SQL']
    abort 'Usage: SQL="..." bin/rails db:exec_all_tenants (or SQL_FILE=path/to.sql)' if sql.blank?

    campaigns = if ENV['SLUG'].present?
      campaign = Campaign.find_by(slug: ENV['SLUG'])
      abort "No campaign found with slug '#{ENV['SLUG']}'" unless campaign
      [campaign]
    else
      Campaign.all.to_a
    end

    campaigns.each do |campaign|
      Apartment::Tenant.switch(campaign.schema_name) do
        result = ActiveRecord::Base.connection.execute(sql)
        puts "#{campaign.slug} (#{campaign.schema_name}): #{result.cmd_tuples} row(s) affected"
      end
    rescue StandardError => e
      puts "#{campaign.slug} (#{campaign.schema_name}): FAILED - #{e.message}"
    end
  end
end
