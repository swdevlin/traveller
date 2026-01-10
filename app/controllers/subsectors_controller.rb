class SubsectorsController < ApplicationController
  before_action :set_subsector, only: %i[ show edit update clear]

  # GET /subsectors or /subsectors.json
  def index
    @subsectors = Subsector.all
  end

  # GET /subsectors/1 or /subsectors/1.json
  def show
    @star_system_count =
      StarSystem.joins(:parsec).where(parsecs: { sector_id: @subsector.sector_id }).count

    @rogue_count =
      StellarObject
        .joins(:parsec)
        .where(parsecs: { sector_id: @subsector.sector_id })
        .where(star_system_id: nil)
        .count
  end

  # GET /subsectors/1/edit
  def edit
  end

  def clear
    Subsector.transaction do
      @subsector.clear
    end
    redirect_to subsector_path(@subsector), notice: 'Subsector cleared.'
  end


  # PATCH/PUT /subsectors/1 or /subsectors/1.json
  def update
    respond_to do |format|
      if @subsector.update(subsector_params)
        format.html { redirect_to @subsector, notice: 'Subsector was successfully updated.', status: :see_other }
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
      params.expect(subsector: [:name, :x, :y, :notes, :build])
    end
end
