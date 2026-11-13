# Distinct people who opened the starmap.
class FeatureUsage::StarmapMetric < FeatureUsage::TableMetric
  EVENT = 'Used starmap'

  def title
    'Starmap'
  end

  def columns
    @columns ||= [FeatureUsage::Column.new(key: :starmap_users, label: 'Users', event: EVENT, distinct: :person)]
  end
end
