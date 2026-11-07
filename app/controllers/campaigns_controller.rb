class CampaignsController < ApplicationController
  allow_without_campaign

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    if @campaign.save
      redirect_to sectors_path(campaign_slug: @campaign.slug)
    else
      render :new, status: :unprocessable_entity
    end
  end

  def search_sectors
    @query = params[:q].to_s.strip
    @sectors = @query.length >= 3 ? TravellerMap.new.find_sectors(name: @query) : []
  end

  private

  def campaign_params
    params.expect(campaign: [:name, :slug, :campaign_type, :sector_source, :exploration,
                              :initial_sector_name, :starting_sector_x, :starting_sector_y])
  end
end
