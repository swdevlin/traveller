# frozen_string_literal: true

class Api::JumpRouteLinksController < Api::BaseController
  SELECTION_ERROR = 'exactly one of sector coordinates (sx, sy) or a bounding box (ulx, uly, lrx, lry) must be given'.freeze

  def index
    sector_given = params[:sx].present? || params[:sy].present?
    box_given = %i[ulx uly lrx lry].any? { |key| params[key].present? }
    return render json: { error: SELECTION_ERROR }, status: :bad_request if sector_given && box_given

    parsecs = parsecs_in_region
    return render json: { error: 'either sector coordinates (sx, sy) or bounding box (ulx, uly, lrx, lry) required' },
                  status: :bad_request if parsecs.nil?

    star_system_ids = StarSystem.where(parsec: parsecs).select(:id)
    links = JumpRouteLink.where(from_star_system_id: star_system_ids)
                         .or(JumpRouteLink.where(to_star_system_id: star_system_ids))
                         .includes(:jump_route, from_star_system: :parsec, to_star_system: :parsec)

    render json: links.map { |link| serialize_link(link) }
  end

  private

  def serialize_link(link)
    {
      id: link.id,
      jump_route_id: link.jump_route_id,
      colour: link.jump_route.colour,
      known: link.jump_route.known?,
      route_type: link.jump_route.route_type,
      stroke_dasharray: link.jump_route.stroke_dasharray.to_s,
      line_width: link.jump_route.line_width,
      from_survey_index: link.from_star_system.survey_index.to_i,
      to_survey_index: link.to_star_system.survey_index.to_i,
      from_x: link.from_star_system.parsec.x,
      from_y: link.from_star_system.parsec.y,
      to_x: link.to_star_system.parsec.x,
      to_y: link.to_star_system.parsec.y
    }
  end
end
