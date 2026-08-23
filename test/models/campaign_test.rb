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
end
