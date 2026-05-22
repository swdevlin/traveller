require 'test_helper'

class JumpRouteLinkTest < ActiveSupport::TestCase
  setup do
    @jump_route = jump_routes(:one)
    @sys_a      = star_systems(:in_one)
    @sys_b      = star_systems(:in_two)
  end

  test 'valid link' do
    link = JumpRouteLink.new(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)
    assert link.valid?
  end

  test 'normalises direction so lower id is always from' do
    higher, lower = [@sys_a, @sys_b].sort_by(&:id).reverse
    link = JumpRouteLink.new(jump_route: @jump_route, from_star_system: higher, to_star_system: lower)
    link.valid?
    assert_equal lower.id, link.from_star_system_id
    assert_equal higher.id, link.to_star_system_id
  end

  test 'rejects self-link' do
    link = JumpRouteLink.new(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_a)
    assert link.invalid?
    assert_includes link.errors[:base], 'A link cannot connect a system to itself'
  end

  test 'rejects duplicate link' do
    JumpRouteLink.create!(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)
    dup = JumpRouteLink.new(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)
    assert dup.invalid?
    assert dup.errors[:from_star_system_id].any?
  end

  test 'duplicate detected regardless of direction' do
    JumpRouteLink.create!(jump_route: @jump_route, from_star_system: @sys_a, to_star_system: @sys_b)
    reversed = JumpRouteLink.new(jump_route: @jump_route, from_star_system: @sys_b, to_star_system: @sys_a)
    assert reversed.invalid?
  end

  test 'other_system returns the partner' do
    link = jump_route_links(:one)
    from = link.from_star_system
    to   = link.to_star_system
    assert_equal to,   link.other_system(from)
    assert_equal from, link.other_system(to)
  end
end
