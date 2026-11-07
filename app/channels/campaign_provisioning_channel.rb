class CampaignProvisioningChannel < ApplicationCable::Channel
  def subscribed
    campaign = Campaign.find(params[:id])
    stream_for campaign
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
  end
end
