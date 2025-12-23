class SolarSystemsController < ApplicationController
  before_action :set_solar_system, only: %i[ show edit update destroy ]

  # GET /solar_systems or /solar_systems.json
  def index
    @solar_systems = SolarSystem.all
  end

  # GET /solar_systems/1 or /solar_systems/1.json
  def show
  end

  # GET /solar_systems/new
  def new
    @solar_system = SolarSystem.new
  end

  # GET /solar_systems/1/edit
  def edit
  end

  # POST /solar_systems or /solar_systems.json
  def create
    @solar_system = SolarSystem.new(solar_system_params)

    respond_to do |format|
      if @solar_system.save
        format.html { redirect_to @solar_system, notice: "Solar system was successfully created." }
        format.json { render :show, status: :created, location: @solar_system }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @solar_system.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /solar_systems/1 or /solar_systems/1.json
  def update
    respond_to do |format|
      if @solar_system.update(solar_system_params)
        format.html { redirect_to @solar_system, notice: "Solar system was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @solar_system }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @solar_system.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /solar_systems/1 or /solar_systems/1.json
  def destroy
    @solar_system.destroy!

    respond_to do |format|
      format.html { redirect_to solar_systems_path, notice: "Solar system was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_solar_system
      @solar_system = SolarSystem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def solar_system_params
      params.expect(solar_system: [:x, :y, :name, :sector_id, :origin_x, :origin_y, :meta])
    end
end
