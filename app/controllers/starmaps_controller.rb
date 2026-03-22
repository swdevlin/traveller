# frozen_string_literal: true

class StarmapsController < ApplicationController
  layout 'starmap', only: :show
  optional_authentication only: :show

  def show
    all_sectors_map_url =
      if Current.campaign
        map_path = AllSectorsMapGenerator.new(Current.campaign).output_path
        campaign_all_sectors_map_url(v: map_path.mtime.to_i) if map_path.exist?
      end

    @starmap_flags = {
      referee: Current.user.present?,
      campaignSlug: params[:campaign_slug],
      campaignName: Current.campaign&.name,
      shipName: Ship.first&.name,
      apiBaseUrl: "/c/#{params[:campaign_slug]}/api",
      allSectorsMapUrl: all_sectors_map_url,
      nativeSophontColour: Current.campaign&.native_sophont_colour.presence,
      extinctSophontColour: Current.campaign&.extinct_sophont_colour.presence
    }
  end
end
