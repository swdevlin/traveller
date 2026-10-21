class GasGiantsController < ApplicationController
  before_action :set_star

  # GET /stars/1/gas_giants/new
  def new
    @gas_giant = build_gas_giant
  end

  # Saving the gas giant reassigns the system's orbit sequences (see HasOrbit).
  # POST /stars/1/gas_giants
  def create
    @gas_giant = build_gas_giant(gas_giant_params)
    assign_orbit_position(@gas_giant)

    if @gas_giant.save(context: :manual)
      redirect_to stellar_object_path(@gas_giant), notice: 'Gas giant was successfully created.', status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  private
    def set_star
      @star = Star.find(params[:star_id])
    end

    def build_gas_giant(attributes = {})
      data = attributes.delete(:data) || {}
      # diameter, period and axial_tilt are stored in data, so data is merged in rather than assigned over them
      GasGiant.new(orbiting: @star, star_system_id: @star.star_system_id).tap do |gas_giant|
        gas_giant.assign_attributes(attributes)
        gas_giant.data = (gas_giant.data || {}).merge(data)
      end
    end

    def assign_orbit_position(gas_giant)
      position = OrbitPositionCalculator.for_body_orbiting_star(body: gas_giant, star: @star)
      return unless position

      gas_giant.orbit_x = position.x
      gas_giant.orbit_y = position.y
    end

    def gas_giant_params
      params.expect(stellar_object: GasGiant.permitted_params).to_h.with_indifferent_access
    end
end
