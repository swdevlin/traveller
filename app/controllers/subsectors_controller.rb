class SubsectorsController < ApplicationController
  before_action :set_subsector, only: %i[ show edit update destroy ]

  # GET /subsectors or /subsectors.json
  def index
    @subsectors = Subsector.all
  end

  # GET /subsectors/1 or /subsectors/1.json
  def show
  end

  # GET /subsectors/new
  def new
    @subsector = Subsector.new
  end

  # GET /subsectors/1/edit
  def edit
  end

  # POST /subsectors or /subsectors.json
  def create
    @subsector = Subsector.new(subsector_params)

    respond_to do |format|
      if @subsector.save
        format.html { redirect_to @subsector, notice: "Subsector was successfully created." }
        format.json { render :show, status: :created, location: @subsector }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @subsector.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /subsectors/1 or /subsectors/1.json
  def update
    respond_to do |format|
      if @subsector.update(subsector_params)
        format.html { redirect_to @subsector, notice: "Subsector was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @subsector }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subsector.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /subsectors/1 or /subsectors/1.json
  def destroy
    @subsector.destroy!

    respond_to do |format|
      format.html { redirect_to subsectors_path, notice: "Subsector was successfully destroyed.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subsector
      @subsector = Subsector.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subsector_params
      params.expect(subsector: [ :name, :x, :y ])
    end
end
