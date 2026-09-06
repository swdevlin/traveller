# frozen_string_literal: true

class Api::RoutePlansController < Api::BaseController
  LIMIT = 12

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
    refueling                = params[:refueling].presence_in(JumpRoute::REFUELING) || 'any'
    excluded_travel_zone_ids = Array(params[:excluded_travel_zone_ids]).map(&:to_i).select(&:positive?)
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

    hop_timings  = nil
    route_total  = nil
    if plan
      ids           = plan.hops.map { |h| h.system.id }
      systems_by_id = StarSystem.where(id: ids).includes(:main_world).index_by(&:id)
      ordered       = plan.hops.map { |h| systems_by_id[h.system.id] }
      timing        = RouteTiming.new(m_drive: m_drive)
      hop_timings   = timing.timings_for(ordered)
      route_total   = timing.total(hop_timings)
    end

    render json: {
      found:                     plan.present?,
      from:                      system_json(from_system),
      to:                        system_json(to_system),
      jump_range:                jump_range,
      refueling:                 refueling,
      excluded_travel_zone_ids:  excluded_travel_zone_ids,
      m_drive:                   m_drive,
      hops:                      plan ? plan.hops.each_with_index.map { |hop, i| hop_json(hop, hop_timings[i]) } : [],
      total_distance:            plan ? plan.hops.sum(&:distance) : nil,
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

  def systems
    q = params[:q].to_s.strip
    return render json: [] if q.length < 3

    authenticated_by_session?
    is_referee = Current.owns_campaign?

    render json: search_systems(q, is_referee)
  end

  private

  def system_json(system)
    { id: system.id, name: system.name }
  end

  def hop_json(hop, timing)
    {
      system: {
        id:        hop.system.id,
        name:      hop.system.name,
        hex_label: hop.system.hex_label,
        x:         hop.system.x,
        y:         hop.system.y
      },
      distance:          hop.distance,
      transit_hours:     timing.transit_hours,
      elapsed_avg_hours: timing.elapsed_avg_hours
    }
  end

  HEX_CODE_SQL = <<~SQL.squish.freeze
    LPAD((parsecs.x - sec.x * 32 + 1)::text, 2, '0') ||
    LPAD((sec.y * 40 - parsecs.y + 1)::text, 2, '0')
  SQL

  def search_systems(q, is_referee)
    visibility = is_referee ? '' : 'AND (ss.known = true OR ss.survey_index >= 10)'

    sql = <<~SQL
      SELECT ss.id, ss.name,
             word_similarity($1, ss.name) AS score,
             sec.name || ' · ' || #{HEX_CODE_SQL} AS meta
      FROM star_systems ss
      JOIN parsecs ON parsecs.id = ss.parsec_id
      JOIN sectors sec ON sec.id = parsecs.sector_id
      WHERE ss.name IS NOT NULL AND $1 <% ss.name
        #{visibility}
      ORDER BY score DESC, ss.name ASC
      LIMIT #{LIMIT}
    SQL

    rows = ActiveRecord::Base.connection.exec_query(sql, 'RoutePlanSystemSearch', [q])
    rows.map { |r| { id: r['id'], name: r['name'], meta: r['meta'] } }
  end
end
