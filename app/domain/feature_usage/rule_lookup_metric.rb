# Rule search page opens, searches run and result sections expanded. All are
# plain event counts, tracked separately.
class FeatureUsage::RuleLookupMetric < FeatureUsage::TableMetric
  VIEWED_EVENT = 'Viewed rule search'
  SEARCHED_EVENT = 'Searched rules'
  EXPANDED_EVENT = 'Expanded rule results'

  def title
    'Rule lookup'
  end

  def columns
    @columns ||= [
      FeatureUsage::Column.new(key: :rule_views, label: 'Views', event: VIEWED_EVENT),
      FeatureUsage::Column.new(key: :rule_searches, label: 'Searches', event: SEARCHED_EVENT),
      FeatureUsage::Column.new(key: :rule_results, label: 'Results', event: EXPANDED_EVENT)
    ]
  end
end
