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
end
