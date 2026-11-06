# frozen_string_literal: true

class PopulateDeepnightCampaignJob < ApplicationJob
  queue_as :default

  # The campaign's ship starts here. The rest of the Deepnight-defaults sectors
  # are created on demand (the "new sector" flow already picks up Deepnight
  # build data for any coordinate it has it for) rather than pre-seeded here.
  HOME_SECTOR = { x: -10, y: -2 }.freeze

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    source = campaign.source_deepnight_defaults? ? 'deepnight' : 'traveller_map'

    create_allegiances
    create_home_sector(source)
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

  def create_home_sector(source)
    path = Rails.root.join('db', 'data', 'sector_defaults', "#{HOME_SECTOR[:x]}_#{HOME_SECTOR[:y]}.yaml")
    data = YAML.safe_load(File.read(path))

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
