class SubsectorChannel < ApplicationCable::Channel
  def subscribed
    subsector = Subsector.find(params[:id])
    stream_for subsector
  end

  def unsubscribed
  end
end
