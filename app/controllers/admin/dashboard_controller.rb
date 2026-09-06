class Admin::DashboardController < AdminController
  ACTIVITY_WINDOW = 7.days
  PAGE_VIEW_EVENT = 'Viewed page'

  def index
    @campaign_count = Campaign.count
    @referee_count = Campaign.distinct.count(:referee_id)
    @campaigns_by_type = Campaign.group(:campaign_type).count
    @campaigns_created_this_week = Campaign.where(created_at: 1.week.ago..).count
    @campaigns_created_this_month = Campaign.where(created_at: 1.month.ago..).count

    site_wide_visits = site_wide_visit_counts
    @referee_visits_7d = site_wide_visits[:referee_visits]
    @player_visits_7d = site_wide_visits[:player_visits]

    activity_by_campaign = campaign_visit_counts
    @pagy, campaigns_page = pagy(campaigns_by_recent_activity, limit: 10, params: request.query_parameters)
    @campaigns = campaigns_page.map { |campaign| campaign_row(campaign, activity_by_campaign) }
  end

  private

  # Campaigns ordered by the most recent page-view event recorded against
  # them (ever, not just within ACTIVITY_WINDOW), with never-visited
  # campaigns sorted last by creation date.
  def campaigns_by_recent_activity
    last_activity = Ahoy::Event
                     .select("(properties->>'campaign_id')::bigint AS campaign_id", 'MAX(time) AS last_active_at')
                     .where(name: PAGE_VIEW_EVENT)
                     .group("(properties->>'campaign_id')::bigint")

    Campaign.includes(:referee)
            .joins("LEFT JOIN (#{last_activity.to_sql}) AS campaign_activity ON campaign_activity.campaign_id = campaigns.id")
            .order(Arel.sql('campaign_activity.last_active_at DESC NULLS LAST, campaigns.created_at DESC'))
  end

  def campaign_row(campaign, activity_by_campaign)
    sector_count = 0
    star_system_count = 0

    if campaign.schema_name.present?
      Apartment::Tenant.switch(campaign.schema_name) do
        sector_count = Sector.kept.count
        star_system_count = StarSystem.count
      end
    end

    visits = activity_by_campaign[campaign.id] || { referee_visits: 0, player_visits: 0 }

    {
      campaign: campaign,
      sector_count: sector_count,
      star_system_count: star_system_count,
      referee_visits: visits[:referee_visits],
      player_visits: visits[:player_visits]
    }
  rescue StandardError
    { campaign: campaign, sector_count: nil, star_system_count: nil, referee_visits: nil, player_visits: nil }
  end

  # One query for all campaigns, grouped by the campaign_id stored in
  # ahoy_events.properties and by whether the visit's user is that campaign's
  # own referee, to avoid an N+1 query per campaign row.
  def campaign_visit_counts(since: ACTIVITY_WINDOW.ago)
    rows = ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, PAGE_VIEW_EVENT, since])
        SELECT
          (ahoy_events.properties->>'campaign_id')::bigint AS campaign_id,
          ahoy_visits.user_id IS NOT NULL AND ahoy_visits.user_id = campaigns.referee_id AS is_referee,
          COUNT(DISTINCT ahoy_events.visit_id) AS visit_count
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        LEFT JOIN campaigns ON campaigns.id = (ahoy_events.properties->>'campaign_id')::bigint
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
        GROUP BY 1, 2
      SQL
    )

    rows.each_with_object(Hash.new { |h, k| h[k] = { referee_visits: 0, player_visits: 0 } }) do |row, counts|
      bucket = counts[row['campaign_id'].to_i]
      key = row['is_referee'] ? :referee_visits : :player_visits
      bucket[key] = row['visit_count'].to_i
    end
  end

  def site_wide_visit_counts(since: ACTIVITY_WINDOW.ago)
    rows = ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, PAGE_VIEW_EVENT, since])
        SELECT
          ahoy_visits.user_id IS NOT NULL AND ahoy_visits.user_id = campaigns.referee_id AS is_referee,
          COUNT(DISTINCT ahoy_events.visit_id) AS visit_count
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        LEFT JOIN campaigns ON campaigns.id = (ahoy_events.properties->>'campaign_id')::bigint
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
        GROUP BY 1
      SQL
    )

    rows.each_with_object({ referee_visits: 0, player_visits: 0 }) do |row, counts|
      key = row['is_referee'] ? :referee_visits : :player_visits
      counts[key] = row['visit_count'].to_i
    end
  end
end
