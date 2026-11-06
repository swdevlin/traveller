# frozen_string_literal: true

require 'test_helper'

class CampaignSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @campaign = campaigns(:one)
    self.default_url_options = { campaign_slug: @campaign.slug }
  end

  test 'show renders' do
    sign_in_as users(:one)

    get campaign_settings_url

    assert_response :success
  end

  test 'edit renders' do
    sign_in_as users(:one)

    get edit_campaign_settings_url

    assert_response :success
  end

  test 'update stores the sector and subsector capital colours' do
    sign_in_as users(:one)

    patch campaign_settings_url, params: {
      campaign: {
        name: @campaign.name,
        sector_capital_colour: '#ff0000',
        subsector_capital_colour: '#00ff00'
      }
    }

    assert_redirected_to campaign_settings_url
    @campaign.reload

    assert_equal '#ff0000', @campaign.sector_capital_colour
    assert_equal '#00ff00', @campaign.subsector_capital_colour
  end

  test 'update stores the hex size' do
    sign_in_as users(:one)

    patch campaign_settings_url, params: {
      campaign: {
        name: @campaign.name,
        hex_size: 'large'
      }
    }

    assert_redirected_to campaign_settings_url
    @campaign.reload

    assert_equal 'large', @campaign.hex_size
    assert_equal 50, @campaign.hex_size_value
  end
end
