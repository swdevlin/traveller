class PlanetoidBeltsController < ApplicationController
  before_action :set_star

  # GET /stars/1/planetoid_belts/new
  def new
    @planetoid_belt = build_planetoid_belt
  end

  # Saving the belt reassigns the system's orbit sequences (see HasOrbit).
  # POST /stars/1/planetoid_belts
  def create
    @planetoid_belt = build_planetoid_belt(planetoid_belt_params)
    assign_orbit_position(@planetoid_belt)

    if @planetoid_belt.save(context: :manual)
      redirect_to stellar_object_path(@planetoid_belt), notice: 'Planetoid belt was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_star
      @star = Star.find(params[:star_id])
    end

    def build_planetoid_belt(attributes = {})
      data = attributes.delete(:data) || {}
      # composition, period and the rest are stored in data, so data is merged in rather than assigned over them
      PlanetoidBelt.new(orbiting: @star, star_system_id: @star.star_system_id).tap do |belt|
        belt.assign_attributes(attributes)
        belt.data = (belt.data || {}).merge(data)
      end
    end

    def assign_orbit_position(belt)
      position = OrbitPositionCalculator.for_body_orbiting_star(body: belt, star: @star)
      return unless position

      belt.orbit_x = position.x
      belt.orbit_y = position.y
    end

    def planetoid_belt_params
      params.expect(stellar_object: PlanetoidBelt.permitted_params).to_h.with_indifferent_access
    end
end
