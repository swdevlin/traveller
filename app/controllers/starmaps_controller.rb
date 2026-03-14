# frozen_string_literal: true

class StarmapsController < ApplicationController
  layout 'starmap', only: :show
  allow_unauthenticated_access only: :show

  def show
    @starmap_flags = {
      referee: Current.user.present?,
      campaignSlug: params[:campaign_slug],
      campaignName: Current.campaign&.name,
      shipName: Ship.first&.name,
      apiBaseUrl: "/c/#{params[:campaign_slug]}/api"
    }
  end
end
