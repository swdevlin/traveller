# frozen_string_literal: true

require 'test_helper'

class OrbitTypeTest < ActiveSupport::TestCase
  test 'classifies Orbit# 0.5-5 as close' do
    assert_equal :close, OrbitType.role_for_orbit(0.5)
    assert_equal :close, OrbitType.role_for_orbit(1)
    assert_equal :close, OrbitType.role_for_orbit(5)
  end

  test 'classifies Orbit# 6-11 as near' do
    assert_equal :near, OrbitType.role_for_orbit(6)
    assert_equal :near, OrbitType.role_for_orbit(8)
    assert_equal :near, OrbitType.role_for_orbit(11.5)
  end

  test 'classifies Orbit# 12+ as far' do
    assert_equal :far, OrbitType.role_for_orbit(12)
    assert_equal :far, OrbitType.role_for_orbit(13.9)
    assert_equal :far, OrbitType.role_for_orbit(20)
  end

  test 'returns nil for a nil orbit' do
    assert_nil OrbitType.role_for_orbit(nil)
  end
end
