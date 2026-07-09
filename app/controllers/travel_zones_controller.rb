class TravelZonesController < ApplicationController
  before_action :set_travel_zone, only: %i[show edit update destroy]

  def index
    @travel_zones = TravelZone.ordered
  end

  def show
  end

  def new
    @travel_zone = TravelZone.new
  end

  def edit
  end

  def create
    @travel_zone = TravelZone.new(travel_zone_params)

    if @travel_zone.save
      redirect_to @travel_zone, notice: 'Travel zone created.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @travel_zone.update(travel_zone_params)
      redirect_to @travel_zone, notice: 'Travel zone updated.', status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @travel_zone.destroy

    if @travel_zone.errors.any?
      redirect_to travel_zones_path, alert: @travel_zone.errors.full_messages.to_sentence, status: :see_other
    else
      redirect_to travel_zones_path, notice: 'Travel zone deleted.', status: :see_other
    end
  end

  private

  def set_travel_zone
    @travel_zone = TravelZone.find(params.expect(:id))
  end

  def travel_zone_params
    params.expect(travel_zone: [:code, :name, :colour])
  end
end
