# frozen_string_literal: true

class Api::RoutePlansController < Api::BaseController
  before_action :authenticate_user_or_token!, only: %i[save]

  def plan
    authenticated_by_session?
    is_referee = Current.owns_campaign?

    from_system = StarSystem.find_by(id: params[:from_id])
    to_system   = StarSystem.find_by(id: params[:to_id])
    unless from_system && to_system && from_system != to_system
      return render json: { error: 'from_id and to_id must reference two different star systems' },
                    status: :unprocessable_entity
    end

    jump_range               = params[:jump_range].presence&.to_i || 2
    refueling                = params[:refueling].presence || 'any'
    unless JumpRoute::REFUELING.include?(refueling)
      return render json: { error: "refueling must be one of: #{JumpRoute::REFUELING.join(', ')}" },
                    status: :unprocessable_entity
    end

    excluded_travel_zone_ids = comma_list_param(:excluded_travel_zone_ids).map(&:to_i).select(&:positive?)
    m_drive                  = params[:m_drive].presence&.to_i&.clamp(1, 6) || 1

    planner = RoutePlanner.new(
      from_id:                  from_system.id,
      to_id:                    to_system.id,
      jump_range:               jump_range,
      refueling:                refueling,
      excluded_travel_zone_ids: excluded_travel_zone_ids,
      restrict_to_known:        !is_referee
    )
    plan = planner.plan

    jump_timings  = nil
    route_total  = nil
    if plan
      ids           = plan.jumps.map { |h| h.system.id }
      systems_by_id = StarSystem.where(id: ids).includes(:main_world).index_by(&:id)
      ordered       = plan.jumps.map { |h| systems_by_id[h.system.id] }
      timing        = RouteTiming.new(m_drive: m_drive)
      jump_timings   = timing.timings_for(ordered)
      route_total   = timing.total(jump_timings)
    end

    render json: {
      found:                     plan.present?,
      from:                      system_json(from_system),
      to:                        system_json(to_system),
      jump_range:                jump_range,
      refueling:                 refueling,
      excluded_travel_zone_ids:  excluded_travel_zone_ids,
      m_drive:                   m_drive,
      jumps:                     plan ? plan.jumps.each_with_index.map { |jump, i| jump_json(jump, jump_timings[i]) } : [],
      total_distance:            plan ? plan.jumps.sum(&:distance) : nil,
      parsec_distance:           plan ? planner.parsec_distance(from_system, to_system) : nil,
      total_jump_avg_hours:      route_total&.fetch(:jump_avg_hours),
      total_jump_min_hours:      route_total&.fetch(:jump_min_hours),
      total_jump_max_hours:      route_total&.fetch(:jump_max_hours),
      total_transit_hours:       route_total&.fetch(:transit_hours),
      total_avg_hours:           route_total&.fetch(:total_avg_hours),
      total_min_hours:           route_total&.fetch(:total_min_hours),
      total_max_hours:           route_total&.fetch(:total_max_hours)
    }
  end

  def save
    system_ids = Array(params[:system_ids]).map(&:to_i).uniq
    pairs = system_ids.each_cons(2).to_a
    return render json: { error: 'Nothing to save.' }, status: :unprocessable_entity if pairs.empty?

    route = JumpRoute.new(
      name:                     params[:name].presence || 'Saved Route',
      colour:                   params[:colour].presence || '#E87040',
      line_style:               'dashed',
      line_width:               8,
      route_type:               'plotted',
      max_jump:                 params[:jump_range].to_i.clamp(1, 6),
      refueling:                params[:refueling].presence_in(JumpRoute::REFUELING),
      excluded_travel_zone_ids: Array(params[:excluded_travel_zone_ids]).map(&:to_i).select(&:positive?),
      from_star_system_id:      params[:from_id].to_i.nonzero?,
      to_star_system_id:        params[:to_id].to_i.nonzero?,
      m_drive:                  params[:m_drive].presence&.to_i&.clamp(1, 6)
    )

    ActiveRecord::Base.transaction do
      route.save!
      pairs.each do |from_id, to_id|
        JumpRouteLink.create!(jump_route: route, from_star_system_id: from_id, to_star_system_id: to_id)
      end
    end

    render json: { id: route.id, name: route.name, colour: route.colour }, status: :created
  rescue ActiveRecord::RecordInvalid => e
    render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
  end

  private

  def system_json(system)
    { id: system.id, name: system.name }
  end

  def jump_json(jump, timing)
    {
      system: {
        id:        jump.system.id,
        name:      jump.system.name,
        hex_label: jump.system.hex_label,
        x:         jump.system.x,
        y:         jump.system.y
      },
      distance:          jump.distance,
      transit_hours:     timing.transit_hours,
      elapsed_avg_hours: timing.elapsed_avg_hours
    }
  end
end
