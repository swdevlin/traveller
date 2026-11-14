# Help page views, one row per page, with how many distinct campaigns viewed
# each. Views show how much a page is read; campaigns show whether that is one
# campaign reading it repeatedly or many campaigns reading it. Rendered with
# the generic table partial, but grouped by page rather than by campaign.
class FeatureUsage::HelpMetric < FeatureUsage::Metric
  EVENT = 'Viewed help'
  INDEX_PAGE = 'index'

  Header = FeatureUsage::TableMetric::Header
  Cell = FeatureUsage::TableMetric::Cell

  def title
    'Help'
  end

  def to_partial_path
    'admin/metrics/table'
  end

  def headers
    [Header.new('Page', false), Header.new('Views', true), Header.new('Campaigns', true)]
  end

  # Most viewed first.
  def rows
    @rows ||= page_counts.sort_by { |page, counts| [-counts[:views], page] }.map do |page, counts|
      [Cell.new(text: label_for(page)),
       Cell.new(text: counts[:views], numeric: true),
       Cell.new(text: counts[:campaigns], numeric: true)]
    end
  end

  def footer
    [Cell.new(text: 'Total'),
     Cell.new(text: total[:views], numeric: true),
     Cell.new(text: total[:campaigns], numeric: true)]
  end

  def empty_message
    FeatureUsage::TableMetric::EMPTY_MESSAGE
  end

  private

  def label_for(page)
    page == INDEX_PAGE ? 'Help index' : page.titleize
  end

  # { page => { views:, campaigns: } }
  def page_counts
    @page_counts ||= select(group: "ahoy_events.properties->>'page'").to_h do |row|
      [row['page'].to_s, { views: row['views'].to_i, campaigns: row['campaigns'].to_i }]
    end
  end

  def total
    @total ||= select.first.then { |row| { views: row['views'].to_i, campaigns: row['campaigns'].to_i } }
  end

  def select(group: nil)
    page_column = group ? "#{group} AS page," : ''
    group_by = group ? 'GROUP BY 1' : ''
    time_filter = since ? 'AND ahoy_events.time >= :since' : ''

    ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, { event: EVENT, since: since }])
        SELECT #{page_column}
               COUNT(*) AS views,
               COUNT(DISTINCT ahoy_events.properties->>'campaign_id') AS campaigns
        FROM ahoy_events
        WHERE ahoy_events.name = :event #{time_filter}
        #{group_by}
      SQL
    ).to_a
  end
end
