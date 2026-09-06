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
    last_parsec = ship &&
      JumpLog.includes(:to_parsec)
             .where(ship_id: ship.id)
             .order(sequence: :desc, id: :desc)
             .first
             &.to_parsec
    rogue_icon = FontAwesomeIcon.find_by(name: 'fa-rogue-object', style: 'solid')
    facility_icons = Facility.where.not(icon_class: [nil, '']).filter_map do |f|
      parts = f.icon_class.split(' ')
      icon = FontAwesomeIcon.find_by(name: parts[1], style: parts[0].delete_prefix('fa-'))
      next unless icon

      { code: f.code, name: f.name, viewBox: icon.view_box, pathData: icon.path_data }
    end
    facilities = Facility.order(:code).map { |f| { code: f.code, name: f.name } }
    allegiances = SurveyOverlay.allegiance_options.map { |code, name| { code: code, name: name } }
    sectors = SurveyOverlay.sector_options.map { |code, name| { code: code, name: name } }
    subsectors = SurveyOverlay.subsector_options.map { |code, name| { code: code, name: name } }
    @starmap_flags = {
      referee: Current.owns_campaign?,
      campaignSlug: params[:campaign_slug],
      campaignName: Current.campaign&.name,
      sectorCapitalColour: Current.campaign&.sector_capital_colour,
      subsectorCapitalColour: Current.campaign&.subsector_capital_colour,
      ship: ship && { name: ship.name, jDrive: ship.jump_drive, mDrive: ship.m_drive },
      apiBaseUrl: "/c/#{params[:campaign_slug]}/api",
      allSectorsMapUrl: all_sectors_map_url,
      rogueObjectPathData: rogue_icon&.path_data,
      shipLocation: last_parsec ? [last_parsec.x, last_parsec.y] : nil,
      facilityIcons: facility_icons,
      facilities: facilities,
      allegianceOptions: allegiances,
      sectorOptions: sectors,
      subsectorOptions: subsectors,
      theme: helpers.current_theme,
      themeIsLight: helpers.current_theme_light?,
      themeOptions: ApplicationHelper::THEMES.map { |key, info| { key: key, label: info[:label], light: info[:light] } }
    }
    if params[:cx].present? && params[:cy].present?
      @starmap_flags[:centerOn] = [params[:cx].to_i, params[:cy].to_i]
    end
  end
end
