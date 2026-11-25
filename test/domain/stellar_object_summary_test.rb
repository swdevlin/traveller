require 'test_helper'

class StellarObjectSummaryTest < ActiveSupport::TestCase
  setup do
    @campaign = campaigns(:one)
    @context = { city_counts_by_stellar_object_id: {}, planetoid_counts_by_belt_id: {} }
  end

  test 'a gas giant takes the generator data over the column of the same name' do
    giant = stellar_objects(:moons_test_gas_giant)
    giant.update_columns(diameter: nil, data: { 'code' => 'GM', 'diameter' => 100_000 })

    summary = StellarObjectSummary.from_record(giant, campaign: @campaign, render_context: @context)

    assert_equal 'GM', summary['code']
    assert_equal 100_000, summary['diameter']
    assert_equal 10, summary['orbit_type']
    assert_not summary.key?('moons')
    assert_equal '', summary['orbit_sequence']
    assert_not summary.key?('created_at')
  end

  test 'a body with no jump shadow has none' do
    belt = PlanetoidBelt.new(id: 1, orbit: 3.0, au: 1.0, data: {})

    summary = StellarObjectSummary.from_record(belt, campaign: @campaign, render_context: @context.merge(planetoid_counts_by_belt_id: { 1 => 4 }))

    assert_nil summary['jump_shadow']
    assert_equal 4, summary['planetoid_count']
    assert_equal 12, summary['orbit_type']
  end
end
