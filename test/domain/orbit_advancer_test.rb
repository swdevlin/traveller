require 'test_helper'

class OrbitAdvancerTest < ActiveSupport::TestCase
  AU = StellarConstants::AU_TO_KM

  Body = Struct.new(:id, :orbiting_id, :orbit_x, :orbit_y, :au, :eccentricity, :orbit, :diameter, :kind, :period,
                    :retrograde, :data) do
    def longitude_of_periapsis_radians
      data&.dig('longitude_of_periapsis')&.then { |degrees| degrees * Math::PI / 180 }
    end

    def is_a?(klass)
      { Star => :star, Moon => :moon, Ring => :ring }.fetch(klass, nil) == kind || super
    end
  end

  setup do
    @primary = Body.new(1, nil, 0.0, 0.0, nil, 0, nil, nil, :star, nil, false, nil)
    @system = Struct.new(:stars, :stellar_objects).new([], [@primary])
    @radius = OrbitToAu.convert(5) * AU
  end

  def planet(eccentricity: 0, retrograde: false, x: @radius, y: 0.0, period: 360.0)
    Body.new(3, 1, x, y, nil, eccentricity, 5, 12_000, :planet, period, retrograde, nil)
  end

  def advance(bodies, days)
    @system.stellar_objects = [@primary, *bodies]
    OrbitAdvancer.new(@system, days: days).call(apply: false).changes.to_h { |c| [c.body.id, c.to] }
  end

  def bearing(position) = Math.atan2(position[1], position[0]) * 180 / Math::PI

  test 'a circular orbit advances a quarter turn in a quarter of its period' do
    result = advance([planet], 90)

    assert_in_delta 90, bearing(result[3]), 0.01
    assert_in_delta @radius, Math.hypot(*result[3]), 1
  end

  test 'a retrograde body travels the other way' do
    assert_in_delta(-90, bearing(advance([planet(retrograde: true)], 90)[3]), 0.01)
  end

  test 'a negative period is a retrograde orbit' do
    assert_in_delta(-90, bearing(advance([planet(period: -360.0)], 90)[3]), 0.01)
  end

  test 'negative days rewind' do
    assert_in_delta(-90, bearing(advance([planet], -90)[3]), 0.01)
  end

  test 'a full period returns a body to where it started' do
    result = advance([planet(eccentricity: 0.3, x: @radius * 0.8, y: @radius * 0.4)], 360)

    assert_in_delta @radius * 0.8, result[3][0], 1000
    assert_in_delta @radius * 0.4, result[3][1], 1000
  end

  test 'an eccentric orbit stays between periapsis and apoapsis' do
    eccentricity = 0.4
    radius = @radius * 0.9
    [45, 120, 200, 300].each do |days|
      distance = Math.hypot(*advance([planet(eccentricity: eccentricity, x: radius, y: 0.0)], days)[3])

      assert_operator distance, :>=, @radius * (1 - eccentricity) - 1000
      assert_operator distance, :<=, @radius * (1 + eccentricity) + 1000
    end
  end

  test 'uses the longitude of periapsis the generator supplied' do
    # Periapsis points along 180 degrees and the body is on the opposite side, so it starts at apoapsis
    body = planet(eccentricity: 0.4, x: @radius * 1.4, y: 0.0)
    body.data = { 'longitude_of_periapsis' => 180.0 }
    result = advance([body], 180)

    assert_in_delta @radius * 0.6, Math.hypot(*result[3]), 1000
    assert_operator result[3][0], :<, 0
  end

  test 'a body without a longitude of periapsis still moves, on the outbound half of its orbit' do
    # Closer than the semi-major axis at bearing 0, so it is on the outbound half with periapsis behind it
    result = advance([planet(eccentricity: 0.4, x: @radius * 0.9, y: 0.0)], 1)

    assert_equal [3], result.keys
    assert_in_delta 0, bearing(result[3]), 5
  end

  test 'reports a body with no period and does not move the primary' do
    body = planet(period: nil)
    @system.stellar_objects = [@primary, body]
    advancer = OrbitAdvancer.new(@system, days: 10).call(apply: false)

    assert_equal [body], advancer.skipped
    assert_empty advancer.changes
  end

  test 'bodies below a secondary star keep their distance from the body they orbit, not from the primary' do
    secondary_distance = 10 * AU
    secondary = Body.new(2, 1, secondary_distance, 0.0, 10, 0, nil, nil, :star, 3650.0, false, nil)
    planet = Body.new(3, 2, secondary_distance + @radius, 0.0, nil, 0, 5, 12_000, :planet, 360.0, false, nil)
    moon = Body.new(4, 3, planet.orbit_x + (10 * 12_000), 0.0, nil, 0, 10, nil, :moon, 10.0, false, nil)
    result = advance([secondary, planet, moon], 90)

    assert_in_delta secondary_distance, Math.hypot(*result[2]), 1
    assert_in_delta @radius, Math.hypot(result[3][0] - result[2][0], result[3][1] - result[2][1]), 1
    assert_in_delta 120_000, Math.hypot(result[4][0] - result[3][0], result[4][1] - result[3][1]), 1
  end

  test 'a moon follows its planet' do
    moon = Body.new(4, 3, @radius + (10 * 12_000), 0.0, nil, 0, 10, nil, :moon, 10.0, false, nil)
    result = advance([planet, moon], 90)

    assert_in_delta 120_000, Math.hypot(result[4][0] - result[3][0], result[4][1] - result[3][1]), 1
  end
end
