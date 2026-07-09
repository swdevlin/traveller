class SubsectorChannel < ApplicationCable::Channel
  include TenantAware

  def subscribed
    switch_tenant do
      subsector = Subsector.find(params[:id])
      stream_for subsector
    end
  rescue ActiveRecord::RecordNotFound
    reject
  end

  def unsubscribed
  end
end
