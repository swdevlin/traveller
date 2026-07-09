require 'test_helper'

class JumpRouteTest < ActiveSupport::TestCase
  test 'travellermap_allegiance_code allows multiple nil values' do
    JumpRoute.create!(name: 'One', route_type: 'network')
    other = JumpRoute.new(name: 'Two', route_type: 'network')

    assert other.valid?
  end

  test 'travellermap_allegiance_code must be unique when present' do
    JumpRoute.create!(name: 'One', route_type: 'network', travellermap_allegiance_code: 'Im')
    other = JumpRoute.new(name: 'Two', route_type: 'network', travellermap_allegiance_code: 'Im')

    assert_not other.valid?
    assert other.errors[:travellermap_allegiance_code].any?
  end
end
