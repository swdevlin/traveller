class MarketingController < ApplicationController
  allow_unauthenticated_access

  def index
    redirect_to sectors_path if authenticated?
  end

  def fairuse
  end

  def deltas
  end
end
