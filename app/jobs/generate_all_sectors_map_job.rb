# frozen_string_literal: true

class GenerateAllSectorsMapJob < ApplicationJob
  queue_as :default

  def perform(campaign_id)
    campaign = Campaign.find(campaign_id)
    Apartment::Tenant.switch(campaign.schema_name) do
      AllSectorsMapGenerator.new(campaign).call
    end
  end
end
