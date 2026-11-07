class CampaignsController < ApplicationController
  allow_without_campaign

  def new
    @campaign = Campaign.new
  end

  def create
    @campaign = Current.user.campaigns.build(campaign_params)
    if @campaign.save
      if @campaign.awaiting_initial_sector?
        redirect_to campaign_path(@campaign)
      else
        redirect_to sectors_path(campaign_slug: @campaign.slug)
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @campaign = Current.user.campaigns.find_by(id: params[:id])
    return redirect_to new_campaign_path, alert: 'That campaign could not be created. Please try again.' unless @campaign

    ready = Apartment::Tenant.switch(@campaign.schema_name) { Sector.exists? }
    redirect_to sectors_path(campaign_slug: @campaign.slug) if ready
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
