class MarketingController < ApplicationController
  allow_unauthenticated_access

  def index
    return unless authenticated?

    campaign = Campaign.where(referee_id: Current.user.id).first
    if campaign
      redirect_to sectors_path(campaign_slug: campaign.slug)
    else
      redirect_to new_campaign_path
    end
  end

  def fairuse
  end

end
