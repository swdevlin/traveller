# Every metric shown on the admin metrics page. Metrics register themselves by
# subclassing FeatureUsage::Metric (or TableMetric), so to track a new feature:
# emit an Ahoy event carrying campaign_id and write a metric class for it.
module FeatureUsage::Catalogue
  module_function

  def all(since: nil)
    metric_classes.map { |metric_class| metric_class.new(since: since) }.sort_by(&:title)
  end

  # { column_key => count } across every metric, for headline tiles.
  def totals(since: nil)
    all(since: since).map(&:totals).reduce({}, :merge)
  end

  # Subclasses only register once loaded, which in development and test is
  # lazy, so load the namespace first. Resolving by name drops stale classes
  # left over from a code reload.
  def metric_classes
    Rails.autoloaders.main.eager_load_namespace(FeatureUsage)
    FeatureUsage::Metric.descendants.filter_map(&:name).uniq.map(&:constantize).reject(&:abstract?)
  end
end
