class MoonsController < ApplicationController
  before_action :set_stellar_object

  # GET /stellar_objects/1/moons/new
  def new
    @moon = build_moon
  end

  # Saving the moon reassigns the system's orbit sequences (see HasOrbit), so the moons are renumbered
  # by orbit. The user is returned to the planet's page.
  # POST /stellar_objects/1/moons
  def create
    @moon = build_moon(moon_params)
    assign_orbit_position(@moon)

    if @moon.save
      redirect_to stellar_object_path(@stellar_object), notice: 'Moon was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_stellar_object
      @stellar_object = StellarObject.find(params[:stellar_object_id])
    end

    def build_moon(attributes = {})
      Moon.new(attributes.merge(orbiting: @stellar_object, star_system_id: @stellar_object.star_system_id,
                                parsec_id: @stellar_object.parsec_id))
    end

    def assign_orbit_position(moon)
      position = MoonOrbitPosition.new(moon: moon, planet: @stellar_object)
      return unless position.present?

      moon.orbit_x = position.x
      moon.orbit_y = position.y
    end

    def moon_params
      params.require(:stellar_object).permit(*Moon.permitted_params)
    end
end
