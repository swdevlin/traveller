class Admin::DashboardController < AdminController
  ACTIVITY_WINDOW = 7.days
  PAGE_VIEW_EVENT = 'Viewed page'
  STARMAP_EVENT = 'Used starmap'
  STARMAP_PERSON_SQL = 'COALESCE(ahoy_visits.user_id::text, ahoy_visits.visitor_token)'

  def index
    @campaign_count = Campaign.count
    @referee_count = Campaign.distinct.count(:referee_id)
    @campaigns_by_type = Campaign.group(:campaign_type).count
    @campaigns_created_this_week = Campaign.where(created_at: 1.week.ago..).count
    @campaigns_created_this_month = Campaign.where(created_at: 1.month.ago..).count

    site_wide_views = site_wide_view_counts
    @referee_views_7d = site_wide_views[:referee_views]
    @player_views_7d = site_wide_views[:player_views]
    @starmap_users_7d = site_wide_starmap_user_count

    views_by_campaign = campaign_view_counts
    starmap_users_by_campaign = campaign_starmap_user_counts
    @pagy, campaigns_page = pagy(campaigns_by_recent_activity, limit: 10, params: request.query_parameters)
    @campaigns = campaigns_page.map { |campaign| campaign_row(campaign, views_by_campaign, starmap_users_by_campaign) }
  end

  private

  # Campaigns ordered by the most recent page-view or starmap event recorded
  # against them (ever, not just within ACTIVITY_WINDOW), with never-visited
  # campaigns sorted last by creation date.
  def campaigns_by_recent_activity
    last_activity = Ahoy::Event
                     .select("(properties->>'campaign_id')::bigint AS campaign_id", 'MAX(time) AS last_active_at')
                     .where(name: [PAGE_VIEW_EVENT, STARMAP_EVENT])
                     .group("(properties->>'campaign_id')::bigint")

    Campaign.includes(:referee)
            .joins("LEFT JOIN (#{last_activity.to_sql}) AS campaign_activity ON campaign_activity.campaign_id = campaigns.id")
            .order(Arel.sql('campaign_activity.last_active_at DESC NULLS LAST, campaigns.created_at DESC'))
  end

  def campaign_row(campaign, views_by_campaign, starmap_users_by_campaign)
    sector_count = 0
    star_system_count = 0

    if campaign.schema_name.present?
      Apartment::Tenant.switch(campaign.schema_name) do
        sector_count = Sector.kept.count
        star_system_count = StarSystem.count
      end
    end

    views = views_by_campaign[campaign.id] || { referee_views: 0, player_views: 0 }

    {
      campaign: campaign,
      sector_count: sector_count,
      star_system_count: star_system_count,
      referee_views: views[:referee_views],
      player_views: views[:player_views],
      starmap_users: starmap_users_by_campaign[campaign.id] || 0
    }
  rescue StandardError
    { campaign: campaign, sector_count: nil, star_system_count: nil, referee_views: nil, player_views: nil,
      starmap_users: nil }
  end

  # One query for all campaigns, grouped by the campaign_id stored in
  # ahoy_events.properties and by whether the visit's user is that campaign's
  # own referee, to avoid an N+1 query per campaign row. Counts page views
  # (events), not visits.
  def campaign_view_counts(since: ACTIVITY_WINDOW.ago)
    rows = ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, PAGE_VIEW_EVENT, since])
        SELECT
          (ahoy_events.properties->>'campaign_id')::bigint AS campaign_id,
          ahoy_visits.user_id IS NOT NULL AND ahoy_visits.user_id = campaigns.referee_id AS is_referee,
          COUNT(*) AS view_count
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        LEFT JOIN campaigns ON campaigns.id = (ahoy_events.properties->>'campaign_id')::bigint
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
        GROUP BY 1, 2
      SQL
    )

    rows.each_with_object(Hash.new { |h, k| h[k] = { referee_views: 0, player_views: 0 } }) do |row, counts|
      bucket = counts[row['campaign_id'].to_i]
      key = row['is_referee'] ? :referee_views : :player_views
      bucket[key] = row['view_count'].to_i
    end
  end

  def site_wide_view_counts(since: ACTIVITY_WINDOW.ago)
    rows = ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, PAGE_VIEW_EVENT, since])
        SELECT
          ahoy_visits.user_id IS NOT NULL AND ahoy_visits.user_id = campaigns.referee_id AS is_referee,
          COUNT(*) AS view_count
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        LEFT JOIN campaigns ON campaigns.id = (ahoy_events.properties->>'campaign_id')::bigint
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
        GROUP BY 1
      SQL
    )

    rows.each_with_object({ referee_views: 0, player_views: 0 }) do |row, counts|
      key = row['is_referee'] ? :referee_views : :player_views
      counts[key] = row['view_count'].to_i
    end
  end

  # Distinct people who opened the starmap, per campaign. A signed-in user
  # counts once however many browsers they use; an anonymous player counts
  # once per browser (visitor_token). IP is not used as identity because
  # players at one venue share one.
  def campaign_starmap_user_counts(since: ACTIVITY_WINDOW.ago)
    rows = ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, STARMAP_EVENT, since])
        SELECT
          (ahoy_events.properties->>'campaign_id')::bigint AS campaign_id,
          COUNT(DISTINCT #{STARMAP_PERSON_SQL}) AS user_count
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
        GROUP BY 1
      SQL
    )

    rows.to_h { |row| [row['campaign_id'].to_i, row['user_count'].to_i] }
  end

  def site_wide_starmap_user_count(since: ACTIVITY_WINDOW.ago)
    ActiveRecord::Base.connection.select_value(
      Ahoy::Event.sanitize_sql_array([<<~SQL, STARMAP_EVENT, since])
        SELECT COUNT(DISTINCT #{STARMAP_PERSON_SQL})
        FROM ahoy_events
        INNER JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        WHERE ahoy_events.name = ? AND ahoy_events.time >= ?
      SQL
    ).to_i
  end
end
