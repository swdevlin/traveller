# frozen_string_literal: true

require 'test_helper'

class BilateralTradeNumberTest < ActiveSupport::TestCase
  test 'wtn dm bands' do
    { 0 => 0, 5 => 0, 5.5 => 0, 6 => 1, 8 => 1, 9 => 2, 10 => 2, 11 => 3, 12 => 3, 13 => 4, 16 => 4, nil => 0 }.each do |wtn, dm|
      assert_equal dm, BilateralTradeNumber.wtn_dm(wtn), "WTN #{wtn.inspect}"
    end
  end

  test 'distance dm' do
    { 1 => 0, 2 => 0, 3 => -1, 4 => -2, 5 => -4, 6 => -6 }.each do |distance, dm|
      assert_equal dm, BilateralTradeNumber.distance_dm(distance)
    end
  end

  test 'xeno dm follows the characteristic DM scale' do
    { 1 => -2, 2 => -2, 3 => -1, 5 => -1, 6 => 0, 8 => 0, 9 => 1, 11 => 1, 12 => 2, 14 => 2, 15 => 3, 17 => 3, nil => 0 }.each do |xeno, dm|
      assert_equal dm, BilateralTradeNumber.xeno_dm(xeno), "Xenophilia #{xeno.inspect}"
    end
  end

  test 'classification bands' do
    { 0 => 'Opportunistic', 1 => 'Low', 6 => 'Low', 7 => 'Moderate',
      18 => 'Moderate', 19 => 'High', 34 => 'High',
      35 => 'Very High', 50 => 'Very High' }.each do |btn, name|
      assert_equal name, BilateralTradeNumber.classification(btn), "BTN #{btn}"
    end
  end

  test 'calculate sums every term' do
    btn = BilateralTradeNumber.calculate(
      exports: 5, imports: 4, distance: 3, source_wtn: 9, destination_wtn: 6,
      source_xenophilia: 1, destination_xenophilia: 10
    )

    # 5 + 4 + 2 + 1 + (-1) + (-2) + 1
    assert_equal 10, btn[:value]
    assert_equal 'Moderate', btn[:classification]
    assert_equal(-1, btn[:distance_dm])
  end

  test 'is 0 when no goods flow, whatever the DMs' do
    btn = BilateralTradeNumber.calculate(
      exports: 0, imports: 0, distance: 1, source_wtn: 13, destination_wtn: 13,
      source_xenophilia: 17, destination_xenophilia: 17
    )

    assert_equal 0, btn[:value]
    assert_equal 'Opportunistic', btn[:classification]
  end

  test 'is never below 0' do
    btn = BilateralTradeNumber.calculate(
      exports: 1, imports: 0, distance: 6, source_wtn: 2, destination_wtn: 2,
      source_xenophilia: 1, destination_xenophilia: 1
    )

    # 1 - 6 - 2 - 2 would be -9
    assert_equal 0, btn[:value]
    assert_equal 'Opportunistic', btn[:classification]
  end

  test 'is 0 when either wtn is 0' do
    [[0, 10], [10, 0], [0.0, 0.0]].each do |source, destination|
      btn = BilateralTradeNumber.calculate(
        exports: 5, imports: 5, distance: 1, source_wtn: source, destination_wtn: destination
      )

      assert_equal 0, btn[:value], "WTN #{source} and #{destination}"
    end
  end
end
