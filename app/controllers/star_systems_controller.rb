class StarSystemsController < ApplicationController
  before_action :set_star_system, only: %i[ show edit update destroy ]

  # GET /star_systems or /star_systems.json
  def index
    @star_systems = StarSystem.all
  end

  # GET /star_systems/1 or /star_systems/1.json
  def show
  end

  # GET /star_systems/new
  def new
    @star_system = StarSystem.new
  end

  # GET /star_systems/1/edit
  def edit
  end

  # POST /star_systems or /star_systems.json
  def create
    @star_system = StarSystem.new(star_system_params)

    respond_to do |format|
      if @star_system.save
        format.html { redirect_to @star_system, notice: 'Star system was successfully created.' }
        format.json { render :show, status: :created, location: @star_system }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @star_system.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /star_systems/1 or /star_systems/1.json
  def update
    respond_to do |format|
      if @star_system.update(star_system_params)
        format.html { redirect_to @star_system, notice: 'Star system was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @star_system }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @star_system.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /star_systems/1 or /star_systems/1.json
  def destroy
    @star_system.destroy!

    respond_to do |format|
      format.html { redirect_to star_systems_path, notice: 'Star system was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_star_system
      @star_system = StarSystem.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def star_system_params
      params.expect(star_system: [:x, :y, :name, :sector_id, :origin_x, :origin_y, :meta])
    end
end
