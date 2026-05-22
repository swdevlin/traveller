# frozen_string_literal: true

class RoutePlansController < ApplicationController
  def new
    @from_system = StarSystem.find_by(id: params[:from_id])
    @to_system   = StarSystem.find_by(id: params[:to_id])
    @ships       = Ship.all.order(:name)
    @jump_range  = params[:jump_range].presence&.to_i || 2
    @refueling   = params[:refueling].presence_in(%w[any commercial wilderness]) || 'any'

    return unless @from_system && @to_system

    if @from_system == @to_system
      flash.now[:alert] = 'Origin and destination must be different systems.'
      return
    end

    planner = RoutePlanner.new(
      from_id:    @from_system.id,
      to_id:      @to_system.id,
      jump_range: @jump_range,
      refueling:  @refueling
    )
    @plan = planner.plan
    if @plan
      @total_distance   = @plan.hops.sum(&:distance)
      @parsec_distance  = planner.parsec_distance(@from_system, @to_system)
    end
    render :create
  end

  def save
    system_ids = Array(params[:system_ids]).map(&:to_i).uniq
    pairs = system_ids.each_cons(2).to_a

    if pairs.empty?
      render turbo_stream: turbo_stream.replace('route-save-form',
               html: '<div id="route-save-form" class="text-sm text-fg-muted">Nothing to save.</div>'.html_safe)
      return
    end

    route = JumpRoute.create!(
      name:       params[:name].presence || 'Saved Route',
      colour:     params[:colour].presence || '#E87040',
      line_style: 'dashed',
      line_width: 8
    )
    pairs.each do |from_id, to_id|
      JumpRouteLink.create!(
        jump_route: route,
        from_star_system_id: from_id,
        to_star_system_id: to_id
      )
    end

    render turbo_stream: turbo_stream.replace('route-save-form',
             partial: 'route_plans/saved', locals: { route: route })
  end

  def clear
    JumpRoute.find_by(id: params[:id])&.destroy
    redirect_to campaign_settings_path, notice: 'Route cleared.'
  end
end
