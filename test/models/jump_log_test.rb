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
    b.update!(depart_year: 1105, depart_day: 9) # +1 day

    a = jump_logs(:chain_a).reload

    assert_equal 2, a.depart_day
    assert_equal 9, a.arrive_day
  end

  # Travel time and departure rules

  def new_jump(attrs = {})
    JumpLog.new({
      ship: ships(:one), from_parsec: parsecs(:one), to_parsec: parsecs(:two),
      depart_year: 1105, depart_day: 100, arrive_year: 1105, arrive_day: 106
    }.merge(attrs))
  end

  test 'a jump of exactly the minimum travel time is valid' do
    assert new_jump(arrive_day: 106).valid?
  end

  test 'a jump shorter than the minimum travel time is invalid' do
    jump = new_jump(arrive_day: 105)
    assert_not jump.valid?
    assert_includes jump.errors[:arrive_day].join, '6 days'
  end

  test 'a misjump may arrive on any date' do
    assert new_jump(arrive_day: 100, misjump: true).valid?
    assert new_jump(arrive_year: 1104, arrive_day: 300, misjump: true).valid?
  end

  test 'a jump may not depart before the ships latest arrival' do
    # chain_c is ship one's latest jump; it arrives on 1105.022
    latest = jump_logs(:chain_c)
    early  = new_jump(depart_day: latest.arrive_day - 1, arrive_day: latest.arrive_day + 6)
    assert_not early.valid?
    assert_includes early.errors[:depart_day].join, 'previous arrival'
  end

  test 'a jump may depart on the day of the ships latest arrival' do
    latest = jump_logs(:chain_c)
    assert new_jump(depart_day: latest.arrive_day, arrive_day: latest.arrive_day + 6).valid?
  end

  test 'a misjump still may not depart before the ships latest arrival' do
    latest = jump_logs(:chain_c)
    assert_not new_jump(depart_day: latest.arrive_day - 1, arrive_day: latest.arrive_day, misjump: true).valid?
  end

  test 'other ships do not constrain the departure' do
    assert new_jump(ship: ships(:two), depart_day: 1, arrive_day: 7, depart_year: 1105, arrive_year: 1105).valid?
  end

  test 'editing a jump only checks against the jump before it' do
    # chain_b follows chain_a (arrives day 8) and precedes chain_c
    b = jump_logs(:chain_b)
    b.depart_day = 7
    assert_not b.valid?
    b.depart_day = 8
    b.arrive_day = 14
    assert b.valid?
  end

  test 'an old jump can have its notes edited though it breaks the minimum travel time' do
    old = jump_logs(:one) # departs and arrives on the same day
    assert old.update(notes: 'Corrected')
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
