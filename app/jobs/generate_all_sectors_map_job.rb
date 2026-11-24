# frozen_string_literal: true

class GenerateAllSectorsMapJob < ApplicationJob
  queue_as :default

  # One build per campaign at a time. Jobs enqueued meanwhile wait, then find the map fresh and exit.
  limits_concurrency to: 1, key: ->(campaign_id, **) { campaign_id }, duration: 10.minutes

  # force: true rebuilds even if the data is unchanged (e.g. display settings changed).
  def perform(campaign_id, force: false)
    campaign = Campaign.find(campaign_id)
    Apartment::Tenant.switch(campaign.schema_name) do
      generator = AllSectorsMapGenerator.new(campaign)
      generator.call if force || generator.stale?
    end
  end
end
