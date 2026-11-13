# Counts Ahoy events for a set of columns, site-wide or per campaign. Each
# column is one event name; it counts events by default, or distinct values
# when `distinct` is set (:person for distinct people, or the name of an event
# property such as 'star_system_id').
class FeatureUsage
  Column = Data.define(:key, :label, :event, :distinct) do
    def initialize(key:, label:, event:, distinct: nil)
      super
    end
  end

  # A signed-in user counts once however many browsers they use; an anonymous
  # player counts once per browser. IP is not identity: players at one venue
  # share one.
  PERSON_SQL = 'COALESCE(ahoy_visits.user_id::text, ahoy_visits.visitor_token)'

  def initialize(columns:, since: nil)
    @columns = columns
    @since = since
  end

  # { campaign_id => { column_key => count } }; campaigns with no events are absent.
  def by_campaign
    @columns.each_with_object(Hash.new { |h, k| h[k] = zero_counts }) do |column, result|
      rows(column, per_campaign: true).each do |row|
        result[row['campaign_id'].to_i][column.key] = row['value'].to_i if row['campaign_id']
      end
    end
  end

  # { column_key => count } across every campaign.
  def totals
    @columns.to_h do |column|
      [column.key, rows(column, per_campaign: false).first&.fetch('value').to_i]
    end
  end

  # { campaign_id => Time } of the latest event of any of these columns.
  def last_event_at_by_campaign
    names = @columns.map(&:event).uniq
    Ahoy::Event.where(name: names)
               .then { |scope| @since ? scope.where(time: @since..) : scope }
               .group(Arel.sql("(properties->>'campaign_id')::bigint"))
               .maximum(:time)
               .compact
  end

  private

  def zero_counts
    @columns.to_h { |column| [column.key, 0] }
  end

  def rows(column, per_campaign:)
    group_select = per_campaign ? "(ahoy_events.properties->>'campaign_id')::bigint AS campaign_id," : ''
    group_by = per_campaign ? 'GROUP BY 1' : ''
    time_filter = @since ? 'AND ahoy_events.time >= :since' : ''

    ActiveRecord::Base.connection.select_all(
      Ahoy::Event.sanitize_sql_array([<<~SQL, { event: column.event, since: @since, property: column.distinct.to_s }])
        SELECT #{group_select} #{count_sql(column)} AS value
        FROM ahoy_events
        LEFT JOIN ahoy_visits ON ahoy_visits.id = ahoy_events.visit_id
        WHERE ahoy_events.name = :event #{time_filter}
        #{group_by}
      SQL
    )
  end

  def count_sql(column)
    case column.distinct
    when nil then 'COUNT(*)'
    when :person then "COUNT(DISTINCT #{PERSON_SQL})"
    else 'COUNT(DISTINCT ahoy_events.properties->>:property)'
    end
  end
end
