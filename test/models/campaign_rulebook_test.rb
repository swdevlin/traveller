require 'test_helper'

class CampaignRulebookTest < ActiveSupport::TestCase
  test 'valid fixture' do
    assert campaign_rulebooks(:core_enabled).valid?
  end

  test 'rulebook_id is unique' do
    duplicate = CampaignRulebook.new(rulebook_id: campaign_rulebooks(:core_enabled).rulebook_id)
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:rulebook_id], 'has already been taken'
  end

  test 'rejects player_searchable without enabled' do
    campaign_rulebook = CampaignRulebook.new(rulebook_id: rulebooks(:failed_import).id, enabled: false, player_searchable: true)
    assert_not campaign_rulebook.valid?
    assert_includes campaign_rulebook.errors[:player_searchable], 'cannot be set unless the rulebook is enabled for this campaign'
  end

  test 'the database check constraint enforces the same rule independently of model validation' do
    campaign_rulebook = campaign_rulebooks(:core_enabled)

    assert_raises(ActiveRecord::StatementInvalid) do
      campaign_rulebook.update_columns(enabled: false, player_searchable: true)
    end
  end

  test 'enabled scope only includes enabled rows' do
    disabled = CampaignRulebook.create!(rulebook_id: rulebooks(:failed_import).id, enabled: false)
    assert_includes CampaignRulebook.enabled, campaign_rulebooks(:core_enabled)
    assert_not_includes CampaignRulebook.enabled, disabled
  end

  test 'player_searchable scope only includes player-searchable rows' do
    campaign_rulebooks(:core_enabled).update!(player_searchable: false)
    assert_not_includes CampaignRulebook.player_searchable, campaign_rulebooks(:core_enabled)
    assert_includes CampaignRulebook.player_searchable, campaign_rulebooks(:hidden_enabled)
  end

  test 'belongs to a rulebook' do
    assert_equal rulebooks(:core), campaign_rulebooks(:core_enabled).rulebook
  end
end
