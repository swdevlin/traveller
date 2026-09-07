require 'test_helper'

class CampaignTest < ActiveSupport::TestCase
  test 'creating a campaign seeds a CampaignRulebook for every existing rulebook' do
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one))

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal Rulebook.count, CampaignRulebook.count

      core = CampaignRulebook.find_by!(rulebook_id: rulebooks(:core).id)
      assert core.enabled?
      assert core.player_searchable?

      adventure = CampaignRulebook.find_by!(rulebook_id: rulebooks(:failed_import).id)
      assert adventure.enabled?
      assert_not adventure.player_searchable?
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'creating a campaign with no existing rulebooks does not error' do
    Rulebook.delete_all
    campaign = Campaign.create!(name: 'Empty Books Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one))

    Apartment::Tenant.switch(campaign.schema_name) do
      assert_equal 0, CampaignRulebook.count
    end
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  # sector_capital_colour / subsector_capital_colour

  test 'capital colours accept a valid hex colour' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = '#ff0000'
    campaign.subsector_capital_colour = '#00ff00'

    assert campaign.valid?
  end

  test 'capital colours allow blank' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = ''
    campaign.subsector_capital_colour = nil

    assert campaign.valid?
  end

  test 'capital colours reject a non-hex value' do
    campaign = campaigns(:one)
    campaign.sector_capital_colour = 'red'

    assert_not campaign.valid?
    assert_includes campaign.errors[:sector_capital_colour], 'must be a hex colour (#rrggbb)'
  end

  # hex_size

  test 'hex_size defaults to medium on create' do
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one))

    assert_equal 'medium', campaign.hex_size
    assert_equal 40, campaign.hex_size_value
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'hex_size_value maps each size to its pixel value' do
    campaign = campaigns(:one)

    campaign.hex_size = 'small'
    assert_equal 30, campaign.hex_size_value

    campaign.hex_size = 'medium'
    assert_equal 40, campaign.hex_size_value

    campaign.hex_size = 'large'
    assert_equal 50, campaign.hex_size_value
  end

  test 'hex_size allows blank and falls back to medium' do
    campaign = campaigns(:one)
    campaign.hex_size = nil

    assert campaign.valid?
    assert_equal 40, campaign.hex_size_value
  end

  test 'hex_size rejects an unrecognised value' do
    campaign = campaigns(:one)
    campaign.hex_size = 'huge'

    assert_not campaign.valid?
    assert_includes campaign.errors[:hex_size], 'is not included in the list'
  end

  # sector_source

  test 'charted_space campaigns default sector_source to traveller_map on create' do
    campaign = Campaign.create!(name: 'New Campaign', slug: "camp-#{SecureRandom.hex(4)}", referee: users(:one), campaign_type: 'charted_space')

    assert_equal 'traveller_map', campaign.sector_source
  ensure
    Apartment::Tenant.drop(campaign.schema_name) rescue nil
    campaign&.destroy
  end

  test 'charted_space campaigns with a blank sector_source pick it up on the next save' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.sector_source = nil

    campaign.save!

    assert_equal 'traveller_map', campaign.sector_source
  end

  test 'sector_source is left untouched for non-charted_space campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'homebrew'
    campaign.sector_source = nil

    campaign.save!

    assert_nil campaign.sector_source
  end

  test 'sector_source is not overwritten once set' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.sector_source = 'deepnight_defaults'

    campaign.save!

    assert_equal 'deepnight_defaults', campaign.sector_source
  end

  # limited_main_world_eccentricity

  test 'limited_main_world_eccentricity? defaults to false for charted_space campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? defaults to false for homebrew campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'homebrew'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? defaults to false for deepnight_revelation campaigns' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'deepnight_revelation'
    campaign.limited_main_world_eccentricity = nil

    assert_not campaign.limited_main_world_eccentricity?
  end

  test 'limited_main_world_eccentricity? returns the stored value once explicitly set' do
    campaign = campaigns(:one)
    campaign.campaign_type = 'charted_space'
    campaign.limited_main_world_eccentricity = true

    assert campaign.limited_main_world_eccentricity?
  end
end
