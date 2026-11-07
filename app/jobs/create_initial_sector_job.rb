class CreateInitialSectorJob < ApplicationJob
  queue_as :default

  SectorNotFound = Class.new(StandardError)

  def perform(campaign_id)
    campaign = Campaign.find_by(id: campaign_id)
    return unless campaign

    Apartment::Tenant.switch(campaign.schema_name) { create_sector_for(campaign) }
    CampaignProvisioningChannel.broadcast_to(campaign, event: 'ready')
  rescue StandardError => e
    Rails.logger.error("Could not create initial sector for campaign #{campaign_id}: #{e.message}")
    fail_campaign(campaign, e) if campaign
  end

  private

  def create_sector_for(campaign)
    x, y = campaign.starting_sector_x, campaign.starting_sector_y
    if x.blank? || y.blank?
      match = TravellerMap.new.find_sectors(name: campaign.initial_sector_name).find { |s| s['Name'] == campaign.initial_sector_name }
      raise SectorNotFound, "Could not find “#{campaign.initial_sector_name}” on Traveller Map." if match.blank?

      x, y = match['SectorX'], match['SectorY']
    end

    Sector.create!(name: campaign.initial_sector_name, x: x.to_i, y: y.to_i, source: 'traveller_map', populate_subsectors: true)
  end

  def fail_campaign(campaign, error)
    CampaignProvisioningChannel.broadcast_to(campaign, event: 'failed', message: failure_message(error))
    campaign.destroy
  end

  def failure_message(error)
    case error
    when SectorNotFound then error.message
    when ActiveRecord::RecordInvalid then error.record.errors.full_messages.to_sentence
    else 'Something went wrong while setting up the sector. Please try again.'
    end
  end
end
