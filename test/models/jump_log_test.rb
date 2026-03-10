require 'test_helper'

class JumpLogTest < ActiveSupport::TestCase
  test 'misjump defaults to false' do
    assert_not JumpLog.new.misjump?
  end

  test 'changing arrive date shifts all subsequent jump dates' do
    a = jump_logs(:chain_a)
    a.update!(arrive_year: 1105, arrive_day: 10) # +2 days

    b = jump_logs(:chain_b).reload
    c = jump_logs(:chain_c).reload

    assert_equal 10, b.depart_day
    assert_equal 17, b.arrive_day
    assert_equal 17, c.depart_day
    assert_equal 24, c.arrive_day
  end

  test 'changing to_parsec updates from_parsec of next jump only' do
    a    = jump_logs(:chain_a)
    next_parsec = parsecs(:one) # chain_b.from_parsec is currently :two
    a.update!(to_parsec: next_parsec)

    b = jump_logs(:chain_b).reload
    c = jump_logs(:chain_c).reload

    assert_equal next_parsec.id, b.from_parsec_id
    assert_equal parsecs(:one).id, c.from_parsec_id # chain_c.from_parsec unchanged
  end

  test 'changing depart date shifts all preceding jump dates' do
    b = jump_logs(:chain_b)
    b.update!(depart_year: 1105, depart_day: 10) # +2 days

    a = jump_logs(:chain_a).reload

    assert_equal 3,  a.depart_day
    assert_equal 10, a.arrive_day
  end

  test 'changing from_parsec updates to_parsec of previous jump only' do
    b          = jump_logs(:chain_b)
    new_origin = parsecs(:two) # chain_b.from_parsec is currently :two; change to same to test independently
    new_origin = parsecs(:one) # pick something different from current chain_a.to_parsec (:two)

    b.update!(from_parsec: new_origin)

    a = jump_logs(:chain_a).reload

    assert_equal new_origin.id, a.to_parsec_id
  end

  test 'cascade does not affect jumps on other ships' do
    a     = jump_logs(:chain_a)
    other = jump_logs(:two) # different ship, depart_day = 1

    a.update!(arrive_day: 10)

    assert_equal 1, other.reload.depart_day
  end
end
