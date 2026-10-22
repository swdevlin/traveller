class TerrestrialPlanetsController < ApplicationController
  before_action :set_star

  # GET /stars/1/terrestrial_planets/new
  def new
    @terrestrial_planet = build_terrestrial_planet
  end

  # Saving the planet reassigns the system's orbit sequences (see HasOrbit). The user is returned to the new planet's
  # page, where moons can be added.
  # POST /stars/1/terrestrial_planets
  def create
    @terrestrial_planet = build_terrestrial_planet(terrestrial_planet_params)
    assign_orbit_position(@terrestrial_planet)

    if @terrestrial_planet.save(context: :manual)
      redirect_to stellar_object_path(@terrestrial_planet), notice: 'Planet was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_star
      @star = Star.find(params[:star_id])
    end

    def build_terrestrial_planet(attributes = {})
      TerrestrialPlanet.new(attributes.merge(orbiting: @star, star_system_id: @star.star_system_id))
    end

    def assign_orbit_position(planet)
      position = OrbitPositionCalculator.for_body_orbiting_star(body: planet, star: @star)
      return unless position

      planet.orbit_x = position.x
      planet.orbit_y = position.y
    end

    def terrestrial_planet_params
      params.require(:stellar_object).permit(*TerrestrialPlanet.permitted_params)
    end
end
