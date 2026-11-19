# frozen_string_literal: true

require 'test_helper'

class TradeSynergyCalculatorTest < ActiveSupport::TestCase
  def dms(codes)
    TradeGoodsTable.dms_for(codes).index_by { it[:d66] }
  end

  test 'a good flows when the origin sells cheap and the partner pays well' do
    # Industrial worlds produce Common Industrial Goods (+5); Non-Industrial pay +3 for them.
    flowing = TradeSynergyCalculator.goods_flowing(dms(%w[In]), dms(%w[Ni]))
    industrial = flowing.find { it[:d66] == 12 }

    assert_equal 8, industrial[:bonus]
    assert_equal 'common', industrial[:category]
    assert_equal 'Common Industrial Goods', industrial[:name]
  end

  test 'goods with a zero or negative total do not flow' do
    # As has a -4 purchase DM for Common Consumables, so Asteroids cannot export them.
    flowing = TradeSynergyCalculator.goods_flowing(dms(%w[As]), dms(%w[Hi]))

    assert_nil flowing.find { it[:d66] == 15 }
  end

  test 'a negative buy DM is outweighed by a larger sell DM' do
    # Ag has a 0 purchase DM for d66 12 and Ni pays +3; a -1 buy DM against +3 still sums above zero.
    flowing = TradeSynergyCalculator.goods_flowing(
      { 12 => { d66: 12, purchase_dm: -1, sale_dm: 0 } },
      { 12 => { d66: 12, purchase_dm: 0, sale_dm: 3 } }
    )

    assert_equal [2], flowing.map { it[:bonus] }
    assert_equal(-1, flowing.first[:buy_dm])
    assert_equal 3, flowing.first[:sell_dm]
  end

  test 'the same rule applies in the reverse direction' do
    # Partner buys at +3 and the origin sells at -1: inbound flows, outbound (-1 buy... +0 sell) does not.
    origin = { 12 => { d66: 12, purchase_dm: 0, sale_dm: -1 } }
    partner = { 12 => { d66: 12, purchase_dm: 3, sale_dm: 0 } }

    assert_equal [2], TradeSynergyCalculator.goods_flowing(partner, origin).map { it[:bonus] }
    assert_empty TradeSynergyCalculator.goods_flowing(origin, partner)
  end

  test 'a good whose buy and sell DMs sum to zero or less does not flow' do
    flowing = TradeSynergyCalculator.goods_flowing(
      { 12 => { d66: 12, purchase_dm: -3, sale_dm: 0 } },
      { 12 => { d66: 12, purchase_dm: 0, sale_dm: 3 } }
    )

    assert_empty flowing
  end

  test 'the two directions are computed independently' do
    outbound = TradeSynergyCalculator.goods_flowing(dms(%w[In]), dms(%w[Ni]))
    inbound = TradeSynergyCalculator.goods_flowing(dms(%w[Ni]), dms(%w[In]))

    refute_equal outbound.map { it[:d66] }, inbound.map { it[:d66] }
  end

  test 'goods are ordered by bonus descending' do
    flowing = TradeSynergyCalculator.goods_flowing(dms(%w[In Ht]), dms(%w[Ni Ri]))

    assert_equal flowing.map { it[:bonus] }.sort.reverse, flowing.map { it[:bonus] }
  end

  test 'systems with no trade codes produce no goods' do
    assert_empty TradeSynergyCalculator.goods_flowing({}, {})
  end

  test 'a good the seller cannot buy does not flow when seller codes are given' do
    # Robots (46) are only available at In worlds; Ag has no purchase DM issue but no availability.
    seller = dms(%w[Ag In])
    buyer = dms(%w[Ni])
    with_in = TradeSynergyCalculator.goods_flowing(seller, buyer, from_codes: %w[Ag In])
    without_in = TradeSynergyCalculator.goods_flowing(seller, buyer, from_codes: %w[Ag])

    assert(with_in.any? { it[:d66] == 46 } || with_in.any? { it[:d66] == 43 })
    assert_nil without_in.find { [43, 46].include?(it[:d66]) }
  end

  test 'common goods are always available to the seller' do
    flowing = TradeSynergyCalculator.goods_flowing(dms(%w[In]), dms(%w[Ni]), from_codes: [])

    assert(flowing.any? { it[:d66] == 12 })
  end
end
