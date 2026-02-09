class SectorsController < ApplicationController
  before_action :set_sector, only: %i[ show edit update destroy clear load_defaults populate generate]

  # GET /sectors or /sectors.json
  def index
    @q = params[:q].to_s.strip
    scope = Sector.kept.order(:name)
    scope = scope.where('LOWER(name) LIKE ?', "%#{@q.downcase}%") if params[:q].present?
    @pagy, @sectors = pagy(scope, limit: 10, params: request.query_parameters)
  end

  def populate
    @star_system_count =
      StarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id }).count

    @rogue_count =
      StellarObject
        .joins(:parsec)
        .where(parsecs: { sector_id: @sector.id })
        .where(orbiting_star_id: nil)
        .count
  end

  def load_defaults
    count = 0
    @sector.subsectors.where(build: nil).find_each do |subsector|
      subsector.load_sector_defaults!
      if subsector.build.present? && subsector.save
        count += 1
      end
    end

    if count > 0
      redirect_to populate_sector_path(@sector), notice: "Defaults loaded for #{count} #{'subsector'.pluralize(count)}."
    else
      redirect_to populate_sector_path(@sector), alert: 'No defaults found for this sector.'
    end
  end

  def generate
    if @sector.subsectors.where(build: nil).exists?
      redirect_to sector_path(@sector), notice: 'Not all subsectors have a build plan. No tasks were created'
    else
      @sector.subsectors.each do |subsector|
        GenerateSubsectorJob.perform_later(subsector, subsector.build)
      end
      redirect_to sector_path(@sector), notice: 'Subsector populate tasks created'
    end
  end

  # GET /sectors/1 or /sectors/1.json
  def show
    @star_system_count =
      StarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id }).count

    @rogue_count =
      StellarObject
        .joins(:parsec)
        .where(parsecs: { sector_id: @sector.id })
        .where(orbiting_star_id: nil)
        .count

    position = Sector.kept.where('LOWER(name) < ?', @sector.name.downcase).count + 1
    @page = (position + 9) / 10
  end

  def new_from_traveller_map
    @query = params[:q].to_s.strip
    @sectors = []
    @existing_sectors = {}

    if @query.length >= 3
      traveller_map = TravellerMap.new
      @sectors = traveller_map.find_sectors(name: @query)

      # Build a lookup of existing sectors by coordinates
      coords = @sectors.map { |s| [s['SectorX'], s['SectorY']] }
      Sector.kept.where(x: coords.map(&:first), y: coords.map(&:second)).find_each do |sector|
        @existing_sectors[[sector.x, sector.y]] = sector
      end
    end
  end

  # GET /sectors/new
  def new
    @sector = Sector.new
  end

  def clear
    Sector.transaction do
      @sector.clear
    end
    redirect_to sector_path(@sector), notice: 'Sector cleared.'
  end

  # GET /sectors/1/edit
  def edit
  end

  # POST /sectors or /sectors.json
  def create
    @sector = Sector.new(sector_params)

    respond_to do |format|
      if @sector.save
        if @sector.source == 'traveller_map'
          format.html { redirect_to sectors_path, notice: "#{@sector.name} sector import started. Subsectors are being created in the background." }
        else
          format.html { redirect_to @sector, notice: 'Sector was successfully created.' }
        end
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
        format.html { redirect_to @sector, notice: 'Sector was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @sector }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @sector.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /sectors/1 or /sectors/1.json
  def destroy
    @sector.discard
    @sector.save
    DeleteSectorJob.perform_later(@sector)

    respond_to do |format|
      format.html { redirect_to sectors_path, notice: 'Sector deleted.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_sector
      @sector = Sector.kept.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sector_params
      params.expect(sector: [:name, :x, :y, :abbreviation, :notes, :build, :source])
    end
end
