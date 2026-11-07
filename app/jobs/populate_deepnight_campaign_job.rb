# frozen_string_literal: true

class PopulateDeepnightCampaignJob < ApplicationJob
  queue_as :default

  # The campaign's ship starts here. The rest of the Deepnight-defaults sectors
  # are created on demand via the registry, using the same subsector jobs.
  HOME_SECTOR = { x: -10, y: -2 }.freeze

  def perform(campaign_id, remaining: false)
    campaign = Campaign.find(campaign_id)
    return unless campaign.deepnight_revelation?

    source = campaign.source_deepnight_defaults? ? 'deepnight' : 'traveller_map'

    campaign.with_lock do
      create_allegiances
      catalogue = remaining ? DeepnightDefaults.sectors : [home_sector_data]
      catalogue.each { |data| create_sector(source, data) }
    end
  end

  private

  def create_allegiances
    path = Rails.root.join('db', 'data', 'deepnight_allegiances.yaml')
    YAML.safe_load(File.read(path)).each do |attrs|
      Allegiance.find_or_create_by(code: attrs['code']) do |a|
        a.name              = attrs['name']
        a.background_colour = attrs['background_colour']
        a.border_colour     = attrs['border_colour']
      end
    end
  end

  def home_sector_data
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{HOME_SECTOR[:x]}_#{HOME_SECTOR[:y]}.yaml")
    YAML.safe_load(File.read(path))
  end

  def create_sector(source, data)
    sector = Sector.find_or_initialize_by(x: data['X'], y: data['Y'])
    return unless sector.new_record?

    sector.name = data['name']
    sector.abbreviation = data['abbreviation']
    sector.source = source
    sector.skip_subsector_creation = true
    sector.save!

    (data['subsectors'] || []).each do |subsector_data|
      enqueue_subsector(sector, subsector_data)
    end
  end

  def enqueue_subsector(sector, subsector_data)
    letter = subsector_data['index']
    index = letter.ord - 'A'.ord
    sx = (index % 4) + 1
    sy = (index / 4) + 1
    CreateSubsectorJob.perform_later(sector.id, letter, sx, sy, subsector_data['name'], nil, 'default', true)
  end
end
