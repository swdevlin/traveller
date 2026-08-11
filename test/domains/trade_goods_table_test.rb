# frozen_string_literal: true

require 'test_helper'

class TradeGoodsTableTest < ActiveSupport::TestCase
  test 'has exactly 36 rows, one per D66 code' do
    assert_equal 36, TradeGoodsTable::GOODS.length
    assert_equal (11..16).to_a + (21..26).to_a + (31..36).to_a + (41..46).to_a + (51..56).to_a + (61..66).to_a,
                 TradeGoodsTable::GOODS.map { |r| r[:d66] }
  end

  test 'for returns the row matching the given d66' do
    row = TradeGoodsTable.for(21)

    assert_equal 'Advanced Electronics', row[:name]
    assert_equal :trade, row[:category]
  end

  test 'for returns nil for an unknown d66' do
    assert_nil TradeGoodsTable.for(99)
  end

  test 'common goods (11-16) are available on all worlds' do
    (11..16).each do |d66|
      assert_equal :all, TradeGoodsTable.for(d66)[:availability], d66
      assert_equal :common, TradeGoodsTable.for(d66)[:category], d66
    end
  end

  test 'trade goods (21-56) list specific trade-code availability' do
    (21..56).select { |d66| TradeGoodsTable.for(d66) }.each do |d66|
      row = TradeGoodsTable.for(d66)
      assert_kind_of Array, row[:availability], d66
      refute_empty row[:availability], d66
    end
  end

  test 'illegal goods (61-65) are categorised distinctly but still priceable' do
    (61..65).each do |d66|
      row = TradeGoodsTable.for(d66)
      assert_equal :illegal, row[:category], d66
      refute_nil row[:base_price], d66
    end
  end

  test 'Exotics (66) has no tons, price or DMs' do
    row = TradeGoodsTable.for(66)

    assert_equal :exotic, row[:category]
    assert_nil row[:base_price]
    assert_nil row[:tons_dice]
    assert_empty row[:purchase_dms]
    assert_empty row[:sale_dms]
  end

  test 'priceable_d66_codes excludes Exotics' do
    codes = TradeGoodsTable.priceable_d66_codes

    assert_equal 35, codes.length
    refute_includes codes, 66
  end
end
