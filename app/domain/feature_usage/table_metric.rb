# Base for metrics shown as a per-campaign table with a totals footer.
# Subclasses define `title` and `columns`; this exposes plain headers, rows and
# footer cells, so one generic partial renders every table.
class FeatureUsage::TableMetric < FeatureUsage::Metric
  abstract!

  Header = Data.define(:label, :numeric)
  Cell = Data.define(:text, :subtext, :numeric) do
    def initialize(text:, subtext: nil, numeric: false)
      super
    end
  end

  EMPTY_MESSAGE = 'No activity in this period.'

  def columns
    raise NotImplementedError, "#{self.class} must define columns"
  end

  def to_partial_path
    'admin/metrics/table'
  end

  def headers
    [Header.new('Campaign', false),
     *columns.map { |column| Header.new(column.label, true) },
     Header.new('Last used', false)]
  end

  # Campaigns with activity in the period, busiest first by the first column.
  def rows
    @rows ||= begin
      counts = usage.by_campaign
      last_at = usage.last_event_at_by_campaign
      campaigns = Campaign.where(id: counts.keys).index_by(&:id)
      primary = columns.first.key

      counts.filter_map { |campaign_id, column_counts| row_for(campaigns[campaign_id], column_counts, last_at[campaign_id]) }
            .sort_by { |campaign, _cells| [-counts[campaign.id][primary], campaign.slug] }
            .map(&:last)
    end
  end

  def footer
    [Cell.new(text: 'Total'),
     *columns.map { |column| Cell.new(text: totals[column.key], numeric: true) },
     Cell.new(text: nil)]
  end

  def totals
    @totals ||= usage.totals
  end

  def empty_message
    EMPTY_MESSAGE
  end

  private

  def usage
    @usage ||= FeatureUsage.new(columns: columns, since: since)
  end

  # [campaign, cells], keeping the campaign so rows can be sorted before the
  # cells are all that is left.
  def row_for(campaign, column_counts, last_at)
    return unless campaign

    cells = [Cell.new(text: campaign.slug, subtext: campaign.name),
             *columns.map { |column| Cell.new(text: column_counts[column.key], numeric: true) },
             Cell.new(text: last_at&.to_date&.iso8601)]
    [campaign, cells]
  end
end
