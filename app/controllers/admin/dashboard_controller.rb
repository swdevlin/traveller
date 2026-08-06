class Admin::DashboardController < AdminController
  def index
    @campaign_count = Campaign.count
    @referee_count = Campaign.distinct.count(:referee_id)
    @campaigns_by_type = Campaign.group(:campaign_type).count
    @campaigns_created_this_week = Campaign.where(created_at: 1.week.ago..).count
    @campaigns_created_this_month = Campaign.where(created_at: 1.month.ago..).count
    @campaigns = Campaign.includes(:referee).order(created_at: :desc).map { |campaign| campaign_row(campaign) }
  end

  private

  def campaign_row(campaign)
    sector_count = 0
    star_system_count = 0

    if campaign.schema_name.present?
      Apartment::Tenant.switch(campaign.schema_name) do
        sector_count = Sector.kept.count
        star_system_count = StarSystem.count
      end
    end

    {
      campaign: campaign,
      sector_count: sector_count,
      star_system_count: star_system_count
    }
  rescue StandardError
    { campaign: campaign, sector_count: nil, star_system_count: nil }
  end
end
