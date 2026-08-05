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
end
