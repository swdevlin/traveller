# frozen_string_literal: true

class Api::NetworkLinksController < Api::BaseController
  def index
    links = if parsecs_in_region
              parsec_ids = parsecs_in_region.select(:id)
              star_system_ids = StarSystem.where(parsec_id: parsec_ids).select(:id)
              NetworkLink.where('from_star_system_id IN (?) OR to_star_system_id IN (?)', star_system_ids, star_system_ids)
    else
              NetworkLink.all
    end

    links = links.includes(:communication_network,
                           from_star_system: :parsec,
                           to_star_system: :parsec)

    render json: links.map { |link| serialize_link(link) }
  end

  private

  def serialize_link(link)
    {
      id: link.id,
      colour: link.communication_network.colour,
      known: link.communication_network.known?,
      from_survey_index: link.from_star_system.survey_index.to_i,
      to_survey_index: link.to_star_system.survey_index.to_i,
      from_x: link.from_star_system.parsec.x,
      from_y: link.from_star_system.parsec.y,
      to_x: link.to_star_system.parsec.x,
      to_y: link.to_star_system.parsec.y
    }
  end
end
