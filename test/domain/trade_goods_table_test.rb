require 'test_helper'

class TradeGoodsTableTest < ActiveSupport::TestCase
  test 'dms_for takes the largest matching DM in each direction' do
    goods = TradeGoodsTable.dms_for(%w[In Ri]).index_by { |row| row[:name] }

    electronics = goods.fetch('Common Electronics')
    assert_equal 2, electronics[:purchase_dm] # In +2 beats Ri +1
    assert_equal 0, electronics[:sale_dm]
  end

  test 'dms_for leaves out goods the codes do not affect' do
    assert_empty TradeGoodsTable.dms_for(%w[Zz])
  end

  test 'dms_for includes the amber and red zone keys' do
    amber = TradeGoodsTable.dms_for(['ZA']).find { |row| row[:name] == 'Advanced Weapons' }

    assert_equal 2, amber[:sale_dm]
  end
end
