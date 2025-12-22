class SectorsController < ApplicationController
  before_action :set_sector, only: %i[ show edit update destroy clear ]

  # GET /sectors or /sectors.json
  def index
    @q = params[:q].to_s.strip
    scope = Sector.order(:name)
    scope = scope.where("LOWER(name) LIKE ?", "%#{@q.downcase}%") if params[:q].present?
    @pagy, @sectors = pagy(scope, params: request.query_parameters)
  end

  # GET /sectors/1 or /sectors/1.json
  def show
    @solar_system_count =
      SolarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id }).count

    @rogue_count =
      StellarObject
        .joins(:parsec)
        .where(parsecs: { sector_id: @sector.id })
        .where(solar_system_id: nil)
        .count
  end

  # GET /sectors/new
  def new
    @sector = Sector.new
  end

  def clear
    Sector.transaction do
      @sector.clear
    end
    redirect_to sector_path(@sector), notice: "Sector cleared."
  end

  # GET /sectors/1/edit
  def edit
  end

  # POST /sectors or /sectors.json
  def create
    @sector = Sector.new(sector_params)

    respond_to do |format|
      if @sector.save
        format.html { redirect_to @sector, notice: "Sector was successfully created." }
        format.json { render :show, status: :created, location: @sector }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @sector.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /sectors/1 or /sectors/1.json
  def update
    respond_to do |format|
      if @sector.update(sector_params)
        format.html { redirect_to @sector, notice: "Sector was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @sector }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sector.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sectors/1 or /sectors/1.json
  def destroy
    @sector.destroy!

    respond_to do |format|
      format.html { redirect_to sectors_path, notice: "Sector deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sector
      @sector = Sector.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sector_params
      params.expect(sector: [ :name, :x, :y, :abbreviation, :notes, :build ])
    end
end
