# frozen_string_literal: true

# When a new Rulebook is created (Admin::RulebooksController#create), give every existing
# campaign a CampaignRulebook row for it: enabled by default, and player_searchable by default
# unless it's an adventure (kept referee-only until a referee opts in). This only ever touches
# campaigns that already existed at rulebook-creation time — new campaigns created afterward
# pick up this rulebook automatically via db/seeds/campaign_rulebooks.rb when their tenant is
# created. Not retroactive: existing CampaignRulebook rows for other rulebooks are never touched.
class BackfillCampaignRulebookJob < ApplicationJob
  queue_as :default

  def perform(rulebook_id)
    rulebook = Rulebook.find(rulebook_id)
    row = {
      rulebook_id: rulebook.id,
      enabled: true,
      player_searchable: !rulebook.category_adventure?
    }

    Campaign.find_each do |campaign|
      next if campaign.schema_name.blank?

      Apartment::Tenant.switch(campaign.schema_name) do
        CampaignRulebook.upsert_all([row], unique_by: %i[rulebook_id])
      end
    rescue StandardError => e
      Rails.logger.error("BackfillCampaignRulebookJob failed for campaign ##{campaign.id}: #{e.message}")
    end
  end
end
