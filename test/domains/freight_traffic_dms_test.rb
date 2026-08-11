# frozen_string_literal: true

require 'test_helper'

class FreightTrafficDmsTest < ActiveSupport::TestCase
  test 'returns sourcebook defaults for a campaign with no overrides' do
    campaign = campaigns(:one)

    assert_equal FreightTrafficDms::DEFAULTS, FreightTrafficDms.for(campaign)
  end

  test 'returns sourcebook defaults when campaign is nil' do
    assert_equal FreightTrafficDms::DEFAULTS, FreightTrafficDms.for(nil)
  end

  test 'campaign overrides take precedence over defaults' do
    campaign = campaigns(:one)
    campaign.freight_dm_zone_red = '-1'

    resolved = FreightTrafficDms.for(campaign)

    assert_equal(-1, resolved[:zone_red])
    assert_equal FreightTrafficDms::DEFAULTS[:starport_a], resolved[:starport_a]
  end

  test 'a blank scalar override falls back to the default' do
    campaign = campaigns(:one)
    campaign.freight_dm_zone_red = ''

    resolved = FreightTrafficDms.for(campaign)

    assert_equal FreightTrafficDms::DEFAULTS[:zone_red], resolved[:zone_red]
  end

  test 'population overrides apply per digit, falling back to the default for blank entries' do
    campaign = campaigns(:one)
    campaign.freight_dm_population = ['-9', '', '', '', '', '', '', '', '', '', '', '5']

    resolved = FreightTrafficDms.for(campaign)

    assert_equal(-9, resolved[:population][0]) # ≤1, overridden
    assert_equal FreightTrafficDms::POPULATION_DEFAULTS[1], resolved[:population][1] # 2, falls back
    assert_equal(5, resolved[:population][11]) # 12, overridden
  end

  test 'tech level overrides apply per digit, falling back to the default for blank entries' do
    campaign = campaigns(:one)
    campaign.freight_dm_tech_level = ['-9'] + ([''] * 15) + ['5']

    resolved = FreightTrafficDms.for(campaign)

    assert_equal(-9, resolved[:tech_level][0]) # TL 0, overridden
    assert_equal FreightTrafficDms::TECH_LEVEL_DEFAULTS[7], resolved[:tech_level][7] # TL 7, falls back
    assert_equal(5, resolved[:tech_level][16]) # TL 16, overridden
  end
end
