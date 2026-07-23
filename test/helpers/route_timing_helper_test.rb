require 'test_helper'

class RouteTimingHelperTest < ActionView::TestCase
  include RouteTimingHelper

  # format_duration_hours

  test 'format_duration_hours returns a dash for nil' do
    assert_equal '-', format_duration_hours(nil)
  end

  test 'format_duration_hours formats sub-hour durations as minutes' do
    assert_equal '30m', format_duration_hours(0.5)
  end

  test 'format_duration_hours formats sub-day durations as hours and minutes' do
    assert_equal '5h 30m', format_duration_hours(5.5)
  end

  test 'format_duration_hours formats sub-week durations as days and hours' do
    assert_equal '2d 3h', format_duration_hours((2 * 24) + 3)
  end

  test 'format_duration_hours formats 102 hours as 4d 6h, not 102h' do
    assert_equal '4d 6h', format_duration_hours(102)
  end

  test 'format_duration_hours formats week-plus durations as weeks and hours' do
    assert_equal '1w 5h', format_duration_hours(168 + 5)
  end

  test 'format_duration_hours breaks a large remainder into days too, not raw hours' do
    assert_equal '1w 4d 6h', format_duration_hours(168 + 102)
  end

  test 'format_duration_hours handles a multi-week duration with a days-and-hours remainder' do
    assert_equal '8w 6d 14h', format_duration_hours((8 * 168) + 158)
  end

  # format_duration_range

  test 'format_duration_range shows the average with a symmetric plus-or-minus range' do
    assert_equal '10h 0m (±2h 0m)', format_duration_range(8, 10, 12)
  end
end
