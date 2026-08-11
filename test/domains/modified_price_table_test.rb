# frozen_string_literal: true

require 'test_helper'

class ModifiedPriceTableTest < ActiveSupport::TestCase
  test 'looks up purchase and sale percentages for a roll of 0' do
    assert_equal 175, ModifiedPriceTable.purchase_percent(0)
    assert_equal 40, ModifiedPriceTable.sale_percent(0)
  end

  test 'looks up purchase and sale percentages for a roll of 8' do
    assert_equal 100, ModifiedPriceTable.purchase_percent(8)
    assert_equal 80, ModifiedPriceTable.sale_percent(8)
  end

  test 'clamps rolls below -3 to the -3 row' do
    assert_equal 300, ModifiedPriceTable.purchase_percent(-30)
    assert_equal 10, ModifiedPriceTable.sale_percent(-30)
  end

  test 'clamps rolls above 25 to the 25 row' do
    assert_equal 15, ModifiedPriceTable.purchase_percent(30)
    assert_equal 400, ModifiedPriceTable.sale_percent(30)
  end
end
