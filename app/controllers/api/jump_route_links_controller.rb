# frozen_string_literal: true

class Api::JumpRouteLinksController < Api::BaseController
  def index
    links = if parsecs_in_region
              parsec_ids      = parsecs_in_region.select(:id)
              star_system_ids = StarSystem.where(parsec_id: parsec_ids).select(:id)
              JumpRouteLink.where(from_star_system_id: star_system_ids)
                           .or(JumpRouteLink.where(to_star_system_id: star_system_ids))
    else
              JumpRouteLink.all
    end

    links = links.includes(:jump_route,
                           from_star_system: :parsec,
                           to_star_system: :parsec)

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
