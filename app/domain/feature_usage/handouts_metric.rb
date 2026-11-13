# Player handouts generated, and how many distinct systems they covered.
class FeatureUsage::HandoutsMetric < FeatureUsage::TableMetric
  EVENT = 'Generated handout'

  def title
    'Handouts'
  end

  def columns
    @columns ||= [
      FeatureUsage::Column.new(key: :handouts, label: 'Handouts', event: EVENT),
      FeatureUsage::Column.new(key: :handout_systems, label: 'Systems', event: EVENT, distinct: 'star_system_id')
    ]
  end
end
