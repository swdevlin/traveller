require 'test_helper'

# RulebookSearch's raw SQL must schema-qualify `public.rulebooks`/`public.rulebook_pages`
# explicitly, because Rulebook/RulebookPage are apartment-excluded (pinned to their own
# connection on the public schema) while the search query itself runs on the shared,
# tenant-switched connection. Every fixture-based test elsewhere in this suite runs
# against the default/public schema and would pass even if that qualification were
# missing — CampaignElevator only ever switches tenants for a real /c/:slug HTTP request
# against a genuinely separate schema. This test creates one, to prove the fix actually
# works (and would fail without it: an unqualified reference would silently match the new
# schema's own always-empty shadow copies of these tables and return zero results).
class RulebookSearchTenantIsolationTest < ActionDispatch::IntegrationTest
  test 'search from within a real tenant-switched campaign returns correct results' do
    # The core_enabled fixture loads into the public schema (fixtures load
    # outside any tenant switch), so it would satisfy an unqualified
    # `campaign_rulebooks` join regardless of whether the query is actually
    # tenant-correct. Destroy it so the only row that can satisfy the join is
    # the one created below, explicitly inside the tenant-switched block.
    campaign_rulebooks(:core_enabled).destroy

    schema = "test_tenant_#{SecureRandom.hex(4)}"
    Apartment.connection.execute(%(CREATE SCHEMA "#{schema}"))
    Apartment::Migrator.migrate(schema)
    campaign = campaigns(:one)
    campaign.update_column(:schema_name, schema)

    Apartment::Tenant.switch(schema) do
      CampaignRulebook.create!(rulebook_id: rulebooks(:core).id, enabled: true, player_searchable: true)
    end

    get rulebook_search_url(campaign_slug: campaign.slug), params: { q: 'jump drive' }

    assert_response :success
    # Checking for "Core Rulebook" alone would be a false positive: the page's
    # filter <select> also lists every Rulebook.searchable title via a plain
    # ActiveRecord query, which runs on Rulebook's own pinned public-schema
    # connection regardless of whether the raw-SQL search itself is broken.
    # The highlighted excerpt only ever renders from an actual search hit.
    assert_not_includes @response.body, 'No matches'
    assert_includes @response.body, '<mark'
  ensure
    Apartment::Tenant.drop(schema) rescue nil
  end
end
