# frozen_string_literal: true

class StarmapsController < ApplicationController
  layout 'starmap', only: :show
  optional_authentication only: :show

  def show
    all_sectors_map_url =
      if Current.campaign
        generator = AllSectorsMapGenerator.new(Current.campaign)
        map_path  = generator.output_path
        latest_change = [
          JumpLog.maximum(:updated_at),
          StarSystem.maximum(:updated_at),
          Sector.with_discarded.maximum(:updated_at),
          Sector.with_discarded.maximum(:discarded_at),
          Subsector.maximum(:updated_at)
        ].compact.max
        if !map_path.exist? || (latest_change && latest_change > map_path.mtime)
          map_path = generator.call || map_path
        end
        campaign_all_sectors_map_url(v: map_path.mtime.to_i) if map_path.exist?
      end

    ship = Ship.first
    rogue_icon = FontAwesomeIcon.find_by(name: 'fa-rogue-object', style: 'solid')
    @starmap_flags = {
      referee: Current.user.present?,
      campaignSlug: params[:campaign_slug],
      campaignName: Current.campaign&.name,
      ship: ship && { name: ship.name, jDrive: ship.jump_drive, mDrive: ship.m_drive },
      apiBaseUrl: "/c/#{params[:campaign_slug]}/api",
      allSectorsMapUrl: all_sectors_map_url,
      nativeSophontColour: Current.campaign&.native_sophont_colour.presence,
      extinctSophontColour: Current.campaign&.extinct_sophont_colour.presence,
      rogueObjectPathData: rogue_icon&.path_data
    }
    if params[:cx].present? && params[:cy].present?
      @starmap_flags[:centerOn] = [params[:cx].to_i, params[:cy].to_i]
    end
  end
end
