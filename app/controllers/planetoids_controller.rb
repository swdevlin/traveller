class PlanetoidsController < ApplicationController
  before_action :set_planetoid_belt

  # GET /stellar_objects/1/planetoids/new
  def new
    @planetoid = build_planetoid(orbit: @planetoid_belt.orbit)
  end

  # Saving the planetoid reassigns the system's orbit sequences (see HasOrbit). The user is returned to the belt's
  # page, where the planetoid is listed.
  # POST /stellar_objects/1/planetoids
  def create
    @planetoid = build_planetoid(planetoid_params)
    assign_orbit_position(@planetoid)

    if @planetoid.save(context: :manual)
      redirect_to stellar_object_path(@planetoid_belt), notice: 'Planetoid was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_planetoid_belt
      @planetoid_belt = PlanetoidBelt.find(params[:stellar_object_id])
    end

    # A belt's planetoids orbit the belt's star, and are tied to the belt by planetoid_belt_id.
    def build_planetoid(attributes = {})
      Planetoid.new(attributes.merge(orbiting: @planetoid_belt.orbiting, star_system_id: @planetoid_belt.star_system_id)).tap do |planetoid|
        planetoid.planetoid_belt_id = @planetoid_belt.id
      end
    end

    def assign_orbit_position(planetoid)
      position = OrbitPositionCalculator.for_body_orbiting_star(body: planetoid, star: @planetoid_belt.orbiting)
      return unless position

      planetoid.orbit_x = position.x
      planetoid.orbit_y = position.y
    end

    def planetoid_params
      params.require(:stellar_object).permit(*Planetoid.permitted_params)
    end
end
