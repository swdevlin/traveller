class RegionChannel < ApplicationCable::Channel
  def subscribed
    region = Region.find(params[:id])
    stream_for region
  end

  def unsubscribed
  end
end
