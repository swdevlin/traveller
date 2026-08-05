require 'test_helper'

class BackfillCampaignRulebookJobTest < ActiveJob::TestCase
  setup do
    @schema = "test_tenant_#{SecureRandom.hex(4)}"
    Apartment.connection.execute(%(CREATE SCHEMA "#{@schema}"))
    Apartment::Migrator.migrate(@schema)
    campaigns(:one).update_column(:schema_name, @schema)
  end

  teardown do
    Apartment::Tenant.drop(@schema) rescue nil
  end

  test 'creates an enabled row for a non-adventure rulebook, player_searchable true' do
    BackfillCampaignRulebookJob.perform_now(rulebooks(:core).id)

    Apartment::Tenant.switch(@schema) do
      row = CampaignRulebook.find_by!(rulebook_id: rulebooks(:core).id)
      assert row.enabled?
      assert row.player_searchable?
    end
  end

  test 'creates an enabled row for an adventure rulebook, player_searchable false' do
    BackfillCampaignRulebookJob.perform_now(rulebooks(:failed_import).id)

    Apartment::Tenant.switch(@schema) do
      row = CampaignRulebook.find_by!(rulebook_id: rulebooks(:failed_import).id)
      assert row.enabled?
      assert_not row.player_searchable?
    end
  end

  test 'is idempotent: running twice does not raise or duplicate rows' do
    assert_nothing_raised do
      BackfillCampaignRulebookJob.perform_now(rulebooks(:core).id)
      BackfillCampaignRulebookJob.perform_now(rulebooks(:core).id)
    end

    Apartment::Tenant.switch(@schema) do
      assert_equal 1, CampaignRulebook.where(rulebook_id: rulebooks(:core).id).count
    end
  end
end
