class AllegiancesController < ApplicationController
  before_action :set_allegiance, only: %i[ show edit update destroy toggle_known ]

  # GET /allegiances or /allegiances.json
  def index
    scope = Allegiance.order(:code)
    @pagy, @allegiances = pagy(scope, limit: 10, params: request.query_parameters)
  end

  # GET /allegiances/table
  def table
    scope = Allegiance.order(:code)
    if params[:q].present?
      q = "%#{params[:q].to_s.strip.downcase}%"
      scope = scope.where('LOWER(code) LIKE ? OR LOWER(name) LIKE ?', q, q)
    end
    @pagy, @allegiances = pagy(scope, limit: 10, params: request.query_parameters)
  end

  # GET /allegiances/search
  def search
    scope = Allegiance.order(:code)
    if params[:id].present?
      scope = scope.where(id: params[:id])
    elsif params[:q].present?
      q = "%#{params[:q].to_s.strip.downcase}%"
      scope = scope.where('LOWER(code) LIKE ? OR LOWER(name) LIKE ?', q, q)
    end
    render json: scope.limit(100).map { |a| { id: a.id, code: a.code, name: a.name } }
  end

  # GET /allegiances/1 or /allegiances/1.json
  def show
    position = Allegiance.where('code < ?', @allegiance.code).count + 1
    @page = (position + 9) / 10

    @governments_by_code  = Government.all.index_by(&:code)
    @law_levels_by_code   = LawLevel.all.index_by(&:code)
    @tech_levels_by_code  = TechLevel.all.index_by(&:code)
    @travel_zones_by_id   = TravelZone.all.index_by(&:id)
    @facilities_by_id     = Facility.all.index_by(&:id)
    @trade_codes_by_id    = TradeCode.all.index_by(&:id)
  end

  # PATCH /allegiances/1/toggle_known
  def toggle_known
    @allegiance.update!(known: !@allegiance.known?)
    redirect_to allegiances_path(page: params[:page]), status: :see_other
  end

  def import_from_traveller_map
    ImportTravellerMapAllegiancesJob.perform_later
    redirect_to allegiances_path, notice: 'Importing job queued'#
  end
  # GET /allegiances/new
  def new
    @allegiance = Allegiance.new
    @return_to = request.referer
  end

  # GET /allegiances/1/edit
  def edit
  end

  # POST /allegiances or /allegiances.json
  def create
    @allegiance = Allegiance.new(allegiance_params)

    respond_to do |format|
      if @allegiance.save
        format.html { redirect_to params[:return_to].presence || @allegiance, notice: 'Allegiance was successfully created.' }
        format.json { render :show, status: :created, location: @allegiance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @allegiance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /allegiances/1 or /allegiances/1.json
  def update
    respond_to do |format|
      if @allegiance.update(allegiance_params)
        format.html { redirect_to @allegiance, notice: 'Allegiance was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @allegiance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @allegiance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /allegiances/1 or /allegiances/1.json
  def destroy
    @allegiance.destroy!

    respond_to do |format|
      format.html { redirect_to allegiances_path, notice: 'Allegiance was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allegiance
      @allegiance = Allegiance.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def allegiance_params
      params.expect(allegiance: [:code, :name, :legacy_code, :background_colour, :border_colour])
    end
end
