class SubsectorsController < ApplicationController
  before_action :set_subsector, only: %i[ show edit update ]

  # GET /subsectors or /subsectors.json
  def index
    @subsectors = Subsector.all
  end

  # GET /subsectors/1 or /subsectors/1.json
  def show
  end

  # GET /subsectors/1/edit
  def edit
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

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_subsector
      @subsector = Subsector.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def subsector_params
      params.expect(subsector: [ :name, :x, :y, :notes, :build ])
    end
end
