# frozen_string_literal: true

require 'test_helper'

class MailTrafficDmsTest < ActiveSupport::TestCase
  test 'returns sourcebook defaults for a campaign with no overrides' do
    campaign = campaigns(:one)

    assert_equal MailTrafficDms::DEFAULTS, MailTrafficDms.for(campaign)
  end

  test 'returns sourcebook defaults when campaign is nil' do
    assert_equal MailTrafficDms::DEFAULTS, MailTrafficDms.for(nil)
  end

  test 'campaign overrides take precedence over defaults' do
    campaign = campaigns(:one)
    campaign.mail_dm_ship_armed = '3'

    resolved = MailTrafficDms.for(campaign)

    assert_equal(3, resolved[:ship_armed])
    assert_equal MailTrafficDms::DEFAULTS[:low_tech_world], resolved[:low_tech_world]
  end

  test 'a blank scalar override falls back to the default' do
    campaign = campaigns(:one)
    campaign.mail_dm_ship_armed = ''

    resolved = MailTrafficDms.for(campaign)

    assert_equal MailTrafficDms::DEFAULTS[:ship_armed], resolved[:ship_armed]
  end
end
