# frozen_string_literal: true

module TenantAware
  extend ActiveSupport::Concern

  private

  def switch_tenant(&block)
    campaign = Campaign.find_by(slug: params[:campaign_slug])
    campaign ? Apartment::Tenant.switch(campaign.schema_name, &block) : block.call
  end
end
