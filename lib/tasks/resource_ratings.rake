# frozen_string_literal: true

require 'csv'

namespace :resource_ratings do
  desc 'Export resource ratings for all three categories. Optionally pass SLUG=my-slug to target one campaign.'
  task all: %i[main_worlds terrestrial_planets planetoid_belts]

  desc 'Export resource ratings for main worlds (TerrestrialPlanet and PlanetoidBelt only). Optionally pass SLUG=my-slug to target one campaign.'
  task main_worlds: :environment do
    campaigns = resolve_campaigns
    output_dir = Rails.root.join('tmp', 'exports')
    FileUtils.mkdir_p(output_dir)

    campaigns.each do |campaign|
      print "Exporting main world resource ratings for '#{campaign.slug}'... "
      Apartment::Tenant.switch(campaign.schema_name) do
        main_world_ids = StarSystem.where.not(main_world_id: nil).pluck(:main_world_id)
        objects = StellarObject
          .where(id: main_world_ids, type: %w[TerrestrialPlanet PlanetoidBelt])
          .includes(
            parsec: { sector: :subsectors },
            star_system: { parsec: { sector: :subsectors } }
          )

        path = output_dir.join("#{campaign.slug}_main_worlds.csv")
        row_count = 0
        CSV.open(path, 'w', headers: true) do |csv|
          csv << %w[sector subsector system hex name type uwp world_trade_number resource_rating importance resource_units resource_factor]
          objects.each do |obj|
            parsec = obj.parsec || obj.star_system&.parsec
            next unless parsec

            csv << [
              parsec.sector.name,
              parsec.subsector&.name,
              obj.star_system&.name,
              parsec.hex_code,
              obj.name,
              obj.type,
              obj.uwp,
              obj.world_trade_number,
              obj.resource_rating,
              obj.importance,
              obj.resource_units,
              obj.resource_factor
            ]
            row_count += 1
          end
        end
        puts "#{row_count} rows → #{path}"
      end
    end
  end

  desc 'Export resource ratings for all terrestrial planets. Optionally pass SLUG=my-slug to target one campaign.'
  task terrestrial_planets: :environment do
    campaigns = resolve_campaigns
    output_dir = Rails.root.join('tmp', 'exports')
    FileUtils.mkdir_p(output_dir)

    campaigns.each do |campaign|
      print "Exporting terrestrial planet resource ratings for '#{campaign.slug}'... "
      Apartment::Tenant.switch(campaign.schema_name) do
        objects = TerrestrialPlanet.includes(
          parsec: { sector: :subsectors },
          star_system: { parsec: { sector: :subsectors } }
        )

        path = output_dir.join("#{campaign.slug}_terrestrial_planets.csv")
        row_count = 0
        CSV.open(path, 'w', headers: true) do |csv|
          csv << %w[sector subsector system hex name uwp resource_rating]
          objects.each do |obj|
            parsec = obj.parsec || obj.star_system&.parsec
            next unless parsec

            csv << [
              parsec.sector.name,
              parsec.subsector&.name,
              obj.star_system&.name,
              parsec.hex_code,
              obj.name,
              obj.uwp,
              obj.resource_rating
            ]
            row_count += 1
          end
        end
        puts "#{row_count} rows → #{path}"
      end
    end
  end

  desc 'Export resource ratings for all planetoid belts. Optionally pass SLUG=my-slug to target one campaign.'
  task planetoid_belts: :environment do
    campaigns = resolve_campaigns
    output_dir = Rails.root.join('tmp', 'exports')
    FileUtils.mkdir_p(output_dir)

    campaigns.each do |campaign|
      print "Exporting planetoid belt resource ratings for '#{campaign.slug}'... "
      Apartment::Tenant.switch(campaign.schema_name) do
        objects = PlanetoidBelt.includes(
          parsec: { sector: :subsectors },
          star_system: { parsec: { sector: :subsectors } }
        )

        path = output_dir.join("#{campaign.slug}_planetoid_belts.csv")
        row_count = 0
        CSV.open(path, 'w', headers: true) do |csv|
          csv << %w[sector subsector system hex name resource_rating]
          objects.each do |obj|
            parsec = obj.parsec || obj.star_system&.parsec
            next unless parsec

            csv << [
              parsec.sector.name,
              parsec.subsector&.name,
              obj.star_system&.name,
              parsec.hex_code,
              obj.name,
              obj.resource_rating
            ]
            row_count += 1
          end
        end
        puts "#{row_count} rows → #{path}"
      end
    end
  end
end

def resolve_campaigns
  if ENV['SLUG'].present?
    campaign = Campaign.find_by(slug: ENV['SLUG'])
    abort "No campaign found with slug '#{ENV['SLUG']}'" unless campaign
    [campaign]
  else
    Campaign.all.to_a
  end
end
