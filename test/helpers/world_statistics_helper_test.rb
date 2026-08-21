require 'test_helper'

class WorldStatisticsHelperTest < ActionView::TestCase
  include WorldStatisticsHelper

  FakeStats = Struct.new(:number_of_populated_worlds, :worlds_with_known_census_count, :total_population)

  test 'total_population_display returns an em dash when there are no populated worlds' do
    stats = FakeStats.new(0, 0, 0)

    assert_equal '—', total_population_display(stats)
  end

  test 'total_population_display reports incomplete census data instead of a misleading zero' do
    stats = FakeStats.new(3, 0, 0)

    assert_equal 'incomplete census data', total_population_display(stats)
  end

  test 'total_population_display shows the abbreviated total when census data is known' do
    stats = FakeStats.new(3, 2, 2_500_000)

    assert_includes total_population_display(stats).to_s, '2.5 million'
  end
end
