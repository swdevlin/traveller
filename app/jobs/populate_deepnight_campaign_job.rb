# frozen_string_literal: true

class PopulateDeepnightCampaignJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    source = campaign.source_deepnight_defaults? ? 'deepnight' : 'traveller_map'

    sector_defaults_path = Rails.root.join('db', 'data', 'sector_defaults')

    Dir.glob(sector_defaults_path.join('*.yaml')).sort.each do |path|
      data = YAML.safe_load(File.read(path))
      create_sector(data, source)
    end
  end

  private

  def create_sector(data, source)
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
    CreateSubsectorJob.perform_later(sector.id, letter, sx, sy, subsector_data['name'])
  end
end
