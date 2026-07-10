# frozen_string_literal: true

class Api::JumpRoutesController < Api::BaseController
  before_action :authenticate_user_or_token!, only: %i[update destroy]
  before_action :set_jump_route, only: %i[update destroy]

  def index
    routes = JumpRoute.ordered.includes(:jump_route_links)
    authorized = authenticated_by_session? || authenticated_by_token?
    routes = routes.where(known: true) unless authorized
    render json: routes.map { |route| serialize_route(route, include_notes: authorized) }
  end

  def update
    if @jump_route.plotted?
      return render json: { error: 'Plotted routes must be edited from the jump route page.' },
                    status: :unprocessable_entity
    end

    if @jump_route.update(jump_route_params)
      render json: serialize_route(@jump_route, include_notes: true)
    else
      render json: { errors: @jump_route.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    @jump_route.destroy!
    head :no_content
  end

  private

  def set_jump_route
    @jump_route = JumpRoute.find(params[:id])
  end

  # route_type, from/to_star_system_id, max_jump, refueling and excluded_travel_zone_ids
  # are intentionally not permitted here — this endpoint only ever produces or mutates
  # 'network' routes with none of the plotted-route fields.
  def jump_route_params
    params.permit(:name, :colour, :line_style, :line_width, :known, :notes)
  end

  def serialize_route(route, include_notes:)
    {
      id:         route.id,
      name:       route.name,
      colour:     route.colour,
      line_style: route.line_style,
      line_width: route.line_width,
      known:      route.known?,
      route_type: route.route_type,
      max_jump:   route.max_jump,
      link_count: route.jump_route_links.size,
      notes:      include_notes ? route.notes : nil
    }
  end
end
