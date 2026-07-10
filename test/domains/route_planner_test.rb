require 'test_helper'

class RoutePlannerTest < ActiveSupport::TestCase
  def setup
    @sector = Sector.create!(name: 'Route Planner Test Sector', x: 95, y: 95, abbreviation: 'Rpt')
  end

  def build_planner(**overrides)
    RoutePlanner.new(from_id: 1, to_id: 2, jump_range: 1, refueling: 'any', **overrides)
  end

  def node(**attrs)
    RoutePlanner::SystemNode.new(**{
      id: 99, name: 'Mid', x: 1, y: 0, gas_giant_count: 0, starport_code: nil,
      hex_label: '0101', travel_zone_id: nil, known: false, survey_index: 0
    }.merge(attrs))
  end

  def build_star_system(x, y, **attrs)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!(name: "System #{x},#{y}", parsec: parsec, **attrs)
  end

  test 'wilderness filter rejects an unsurveyed intermediate when restricted to known' do
    planner = build_planner(refueling: 'wilderness', restrict_to_known: true)
    system = node(gas_giant_count: 1, known: false, survey_index: 0)

    assert_not planner.send(:eligible?, system)
  end

  test 'wilderness filter accepts a known intermediate when restricted to known' do
    planner = build_planner(refueling: 'wilderness', restrict_to_known: true)
    system = node(gas_giant_count: 1, known: true, survey_index: 0)

    assert planner.send(:eligible?, system)
  end

  test 'wilderness filter accepts an intermediate surveyed to 10 or above when restricted to known' do
    planner = build_planner(refueling: 'wilderness', restrict_to_known: true)
    system = node(gas_giant_count: 1, known: false, survey_index: 10)

    assert planner.send(:eligible?, system)
  end

  test 'refueling any allows an unsurveyed intermediate as a pass-through even when restricted to known' do
    planner = build_planner(refueling: 'any', restrict_to_known: true)
    system = node(known: false, survey_index: 0)

    assert planner.send(:eligible?, system)
  end

  test 'referee mode ignores known/survey restrictions entirely' do
    planner = build_planner(refueling: 'wilderness', restrict_to_known: false)
    system = node(gas_giant_count: 1, known: false, survey_index: 0)

    assert planner.send(:eligible?, system)
  end

  test 'player mode reports no route when the only path requires an unsurveyed refuelling stop' do
    from = build_star_system(0, 0)
    build_star_system(1, 0, gas_giant_count: 1, known: false, survey_index: 0)
    to = build_star_system(2, 0)

    planner = RoutePlanner.new(from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'wilderness', restrict_to_known: true)

    assert_nil planner.plan
  end

  test 'referee mode finds the same route unrestricted' do
    from = build_star_system(10, 0)
    build_star_system(11, 0, gas_giant_count: 1, known: false, survey_index: 0)
    to = build_star_system(12, 0)

    planner = RoutePlanner.new(from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'wilderness', restrict_to_known: false)
    plan = planner.plan

    assert plan
    assert_equal 3, plan.hops.size
  end

  test 'player mode allows the unsurveyed system as a pass-through when no refuelling filter applies' do
    from = build_star_system(20, 0)
    build_star_system(21, 0, known: false, survey_index: 0)
    to = build_star_system(22, 0)

    planner = RoutePlanner.new(from_id: from.id, to_id: to.id, jump_range: 1, refueling: 'any', restrict_to_known: true)
    plan = planner.plan

    assert plan
    assert_equal 3, plan.hops.size
  end
end
