# frozen_string_literal: true

class StarmapsController < ApplicationController
  layout 'starmap', only: :show
  optional_authentication only: :show

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
