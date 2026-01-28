class TechLevelsController < ApplicationController
  before_action :set_tech_level, only: %i[ show edit update destroy ]

  # GET /tech_levels or /tech_levels.json
  def index
    @tech_levels = TechLevel.all
  end

  # GET /tech_levels/1 or /tech_levels/1.json
  def show
  end

  # GET /tech_levels/new
  def new
    @tech_level = TechLevel.new
  end

  # GET /tech_levels/1/edit
  def edit
  end

  # POST /tech_levels or /tech_levels.json
  def create
    @tech_level = TechLevel.new(tech_level_params)

    respond_to do |format|
      if @tech_level.save
        format.html { redirect_to @tech_level, notice: "Tech level was successfully created." }
        format.json { render :show, status: :created, location: @tech_level }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @tech_level.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /tech_levels/1 or /tech_levels/1.json
  def update
    respond_to do |format|
      if @tech_level.update(tech_level_params)
        format.html { redirect_to @tech_level, notice: "Tech level was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @tech_level }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @tech_level.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /tech_levels/1 or /tech_levels/1.json
  def destroy
    @tech_level.destroy!

    respond_to do |format|
      format.html { redirect_to tech_levels_path, notice: "Tech level was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tech_level
      @tech_level = TechLevel.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def tech_level_params
      params.expect(tech_level: [ :code, :energy, :electronics, :manufacturing, :medical, :environmental, :land, :sea, :air, :space, :personal_military, :heavy_military, :notes ])
    end
end
