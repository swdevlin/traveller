# frozen_string_literal: true

require 'test_helper'

class RoutePlansControllerTest < AuthenticatedIntegrationTest
  setup do
    @campaign = campaigns(:one)
    @sector = Sector.create!(name: 'Route Plan View Test Sector', x: 97, y: 97, abbreviation: 'Rpv')
    @ship = Ship.create!(name: 'Test Courier', jump_drive: 2, m_drive: 2)
  end

  def build_star_system(x, y)
    parsec = Parsec.create!(sector: @sector, x: x, y: y, q: x, r: y, s: -x - y)
    StarSystem.create!(name: "System #{x},#{y}", parsec: parsec)
  end

  test 'keeps the selected ship after plotting a route' do
    from = build_star_system(0, 0)
    to = build_star_system(1, 0)

    get new_route_plan_url(from_id: from.id, to_id: to.id, ship_id: @ship.id, jump_range: 2)

    assert_response :success
    assert_select "select[name='ship_id'] option[selected][value='#{@ship.id}']"
  end

  test 'leaves the ship unselected when none was submitted' do
    get new_route_plan_url

    assert_response :success
    assert_select "select[name='ship_id'] option[selected]", count: 0
  end
end
