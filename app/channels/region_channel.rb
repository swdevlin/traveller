class RegionChannel < ApplicationCable::Channel
  include TenantAware

  def subscribed
    switch_tenant do
      region = Region.find(params[:id])
      stream_for region
    end
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
  end
end
