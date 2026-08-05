# frozen_string_literal: true

# Seeds one CampaignRulebook per existing Rulebook when a new campaign's tenant schema is
# created. Every book starts enabled; every book starts player_searchable except adventures,
# which stay referee-only until explicitly opened up per campaign. Rulebook is apartment-
# excluded (pinned to the public schema), so this reads correctly even though it runs inside
# the new tenant's Apartment::Tenant.switch block (see db/seeds/tenant.rb).

rows = Rulebook.all.map do |rulebook|
  {
    rulebook_id: rulebook.id,
    enabled: true,
    player_searchable: !rulebook.category_adventure?
  }
end

CampaignRulebook.upsert_all(rows, unique_by: %i[rulebook_id]) if rows.any?
