require 'test_helper'

class OrbitPositionRecomputerTest < ActiveSupport::TestCase
  AU = StellarConstants::AU_TO_KM

  Body = Struct.new(:id, :orbiting_id, :orbit_x, :orbit_y, :au, :eccentricity, :orbit, :diameter, :kind) do
    def is_a?(klass)
      { Star => :star, Moon => :moon, Ring => :ring }.fetch(klass, nil) == kind || super
    end
  end

  setup do
    @primary = Body.new(1, nil, 0.0, 0.0, nil, 0, nil, nil, :star)
    @secondary = Body.new(2, 1, 5.0, 5.0, 10, 0, nil, nil, :star)
    @planet = Body.new(3, 2, 1.0, 1.0, nil, 0, 5, 12_000, :planet)
    @moon = Body.new(4, 3, 0.0, 0.0, nil, 0, 10, nil, :moon)
    @system = Struct.new(:stars, :stellar_objects).new([], [@primary, @secondary, @planet, @moon])
  end

  def positions
    OrbitPositionRecomputer.new(@system).call(apply: false).changes.to_h { |c| [c.body.id, c.to] }
  end

  def distance(pos_a, pos_b) = Math.hypot(pos_a[0] - pos_b[0], pos_a[1] - pos_b[1])

  test 'places each body at its own orbital distance from its parent' do
    result = positions

    assert_in_delta 10 * AU, distance(result[2], [0, 0]), 1
    assert_in_delta OrbitToAu.convert(5) * AU, distance(result[3], result[2]), 1
    assert_in_delta 10 * 12_000, distance(result[4], result[3]), 1
  end

  test 'does not place the primary star' do
    assert_not_includes positions.keys, 1
  end

  test 'reports a body with no orbit to place it by' do
    @planet.orbit = nil
    rebaser = OrbitPositionRecomputer.new(@system).call(apply: false)

    assert_equal [@planet], rebaser.skipped
  end
end
