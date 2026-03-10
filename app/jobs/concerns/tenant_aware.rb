# frozen_string_literal: true

module TenantAware
  extend ActiveSupport::Concern

  included do
    around_perform :switch_tenant
  end

  def serialize
    campaign_id = Campaign.find_by(schema_name: Apartment::Tenant.current)&.id
    super.merge('campaign_id' => campaign_id)
  end

  def deserialize(job_data)
    super
    @campaign_id = job_data['campaign_id']
  end

  def current_campaign_id
    @campaign_id
  end

  private

  def switch_tenant(&block)
    if @campaign_id
      schema_name = Campaign.find(@campaign_id).schema_name
      Apartment::Tenant.switch(schema_name, &block)
    else
      block.call
    end
  end
end
