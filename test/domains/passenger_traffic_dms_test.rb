# frozen_string_literal: true

require 'test_helper'

class PassengerTrafficDmsTest < ActiveSupport::TestCase
  test 'returns sourcebook defaults for a campaign with no overrides' do
    campaign = campaigns(:one)

    assert_equal PassengerTrafficDms::DEFAULTS, PassengerTrafficDms.for(campaign)
  end

  test 'returns sourcebook defaults when campaign is nil' do
    assert_equal PassengerTrafficDms::DEFAULTS, PassengerTrafficDms.for(nil)
  end

  test 'campaign overrides take precedence over defaults' do
    campaign = campaigns(:one)
    campaign.passenger_dm_zone_red = '-1'

    resolved = PassengerTrafficDms.for(campaign)

    assert_equal(-1, resolved[:zone_red])
    assert_equal PassengerTrafficDms::DEFAULTS[:starport_a], resolved[:starport_a]
  end

  test 'a blank scalar override falls back to the default' do
    campaign = campaigns(:one)
    campaign.passenger_dm_zone_red = ''

    resolved = PassengerTrafficDms.for(campaign)

    assert_equal PassengerTrafficDms::DEFAULTS[:zone_red], resolved[:zone_red]
  end

  test 'population overrides apply per digit, falling back to the default for blank entries' do
    campaign = campaigns(:one)
    campaign.passenger_dm_population = ['-9', '', '', '', '', '', '', '', '', '', '', '5']

    resolved = PassengerTrafficDms.for(campaign)

    assert_equal(-9, resolved[:population][0]) # ≤1, overridden
    assert_equal PassengerTrafficDms::POPULATION_DEFAULTS[1], resolved[:population][1] # 2, falls back
    assert_equal(5, resolved[:population][11]) # 12, overridden
  end
end
