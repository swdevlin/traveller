require 'test_helper'

class FeatureUsageCatalogueTest < ActiveSupport::TestCase
  test 'lists every concrete metric and not the abstract bases' do
    classes = FeatureUsage::Catalogue.all.map(&:class)

    assert_equal [FeatureUsage::HandoutsMetric, FeatureUsage::RuleLookupMetric, FeatureUsage::StarmapMetric], classes
  end

  test 'totals merge every metric column' do
    assert_equal %i[handouts handout_systems rule_views rule_searches rule_results starmap_users].sort,
                 FeatureUsage::Catalogue.totals.keys.sort
  end
end
