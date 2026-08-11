# frozen_string_literal: true

require 'test_helper'

class CampaignSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    self.default_url_options = { campaign_slug: @campaign.slug }
  end

  test 'show renders the passenger traffic DM groups' do
    sign_in_as users(:one)

    get campaign_settings_url

    assert_response :success
  end

  test 'edit renders the passenger traffic DM groups' do
    sign_in_as users(:one)

    get edit_campaign_settings_url

    assert_response :success
  end

  test 'update stores per-digit population overrides from the array param' do
    sign_in_as users(:one)

    patch campaign_settings_url, params: {
      campaign: {
        name: @campaign.name,
        passenger_dm_population: ['-9', '', '', '', '', '', '', '', '', '', '', '5'],
        passenger_dm_starport_c: '-1'
      }
    }

    assert_redirected_to campaign_settings_url
    @campaign.reload

    dms = PassengerTrafficDms.for(@campaign)
    assert_equal(-9, dms[:population][0])
    assert_equal PassengerTrafficDms::POPULATION_DEFAULTS[1], dms[:population][1]
    assert_equal(5, dms[:population][11])
    assert_equal(-1, dms[:starport_c])
  end

  test 'update stores per-digit freight population and tech level overrides from the array params' do
    sign_in_as users(:one)

    patch campaign_settings_url, params: {
      campaign: {
        name: @campaign.name,
        freight_dm_population: ['-9', '', '', '', '', '', '', '', '', '', '', '5'],
        freight_dm_tech_level: ['-9'] + ([''] * 15) + ['5'],
        freight_dm_starport_c: '-1'
      }
    }

    assert_redirected_to campaign_settings_url
    @campaign.reload

    dms = FreightTrafficDms.for(@campaign)
    assert_equal(-9, dms[:population][0])
    assert_equal FreightTrafficDms::POPULATION_DEFAULTS[1], dms[:population][1]
    assert_equal(5, dms[:population][11])
    assert_equal(-9, dms[:tech_level][0])
    assert_equal FreightTrafficDms::TECH_LEVEL_DEFAULTS[7], dms[:tech_level][7]
    assert_equal(5, dms[:tech_level][16])
    assert_equal(-1, dms[:starport_c])
  end

  test 'update stores mail DM overrides' do
    sign_in_as users(:one)

    patch campaign_settings_url, params: {
      campaign: {
        name: @campaign.name,
        mail_dm_ship_armed: '3',
        mail_dm_freight_dm_very_high: '4'
      }
    }

    assert_redirected_to campaign_settings_url
    @campaign.reload

    dms = MailTrafficDms.for(@campaign)
    assert_equal(3, dms[:ship_armed])
    assert_equal(4, dms[:freight_dm_very_high])
    assert_equal MailTrafficDms::DEFAULTS[:low_tech_world], dms[:low_tech_world]
  end
end
