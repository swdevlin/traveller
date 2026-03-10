class SectorsController < ApplicationController
  before_action :set_sector, only: %i[ show edit update destroy clear load_defaults populate generate defaults_source map ]

  # GET /sectors or /sectors.json
  def index
    @q = params[:q].to_s.strip
    scope = Sector.kept
                  .select('sectors.*, COUNT(star_systems.id) AS star_system_count')
                  .left_joins(parsecs: :star_systems)
                  .group('sectors.id')
                  .order(:name)
    scope = scope.where('LOWER(sectors.name) LIKE ?', "%#{@q.downcase}%") if params[:q].present?
    @pagy, @sectors = pagy(scope, limit: 10, params: request.query_parameters)
  end

  def populate
    @star_system_count =
      StarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id }).count

    @rogue_count =
      StellarObject
        .joins(:parsec)
        .where(parsecs: { sector_id: @sector.id })
        .where(orbiting_id: nil)
        .count
  end

  def load_defaults
    source = params[:source].presence || 'traveller_map'
    count = 0

    @sector.subsectors.each do |subsector|
      case source
      when 'deepnight'
        subsector.load_deepnight_defaults!
      else
        subsector.load_travellermap_defaults!
      end

      if subsector.build.present? && subsector.save
        count += 1
      end
    end

    label = source == 'deepnight' ? 'Deepnight defaults' : 'TravellerMap defaults'

    if count > 0
      redirect_to populate_sector_path(@sector),
                  notice: "#{label} loaded for #{count} #{'subsector'.pluralize(count)}."
    else
      redirect_to populate_sector_path(@sector),
                  alert: "No #{label.downcase} found for this sector."
    end
  end

  def generate
    if @sector.subsectors.where(build: nil).exists?
      redirect_to sector_path(@sector), notice: 'Not all subsectors have a build plan. No tasks were created'
    else
      @sector.subsectors.each do |subsector|
        GenerateSubsectorJob.set(priority: subsector.y * 10 + subsector.x).perform_later(subsector, subsector.build)
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
        .where(orbiting_id: nil)
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

  def defaults_source
    @deepnight_defaults_available = DeepnightDefaults.available?(@sector)
  end

  def map
    sector_ul = @sector.upper_left

    @star_systems = StarSystem
      .joins(:parsec)
      .where(parsecs: { sector_id: @sector.id })
      .includes(:parsec, :allegiance, stars: [])

    max_updated = @star_systems.maximum(:updated_at)
    max_parsec_updated = @sector.parsecs.maximum(:updated_at)
    region_parsec_max = RegionParsec.joins(:parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    region_record_max = Region.joins(region_components: { region_parsecs: :parsec }).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    region_max_updated = [region_parsec_max, region_record_max].compact.max
    jump_max_updated = JumpLog.maximum(:updated_at)
    cache_key = "sector_map/#{@sector.id}/#{@sector.updated_at.to_i}-#{max_updated.to_i}-#{max_parsec_updated.to_i}-#{region_max_updated.to_i}-#{jump_max_updated.to_i}"

    fresh_when etag: cache_key, last_modified: [@sector.updated_at, max_updated, max_parsec_updated, region_max_updated, jump_max_updated].compact.max
    return if performed?

    @systems_by_hex = @star_systems.each_with_object({}) do |sys, h|
      hx = sys.parsec.x - sector_ul.x + 1
      hy = sector_ul.y - sys.parsec.y + 1
      h[format('%04d', hx * 100 + hy)] = sys
    end

    @parsec_ids_by_hex = @sector.parsecs.pluck(:id, :x, :y, :label, :label_colour).to_h do |pid, px, py, lbl, colour|
      hx = px - sector_ul.x + 1
      hy = sector_ul.y - py + 1
      [format('%04d', hx * 100 + hy), { id: pid, label: lbl, colour: colour }]
    end

    sector_parsec_ids = @parsec_ids_by_hex.values.map { |v| v[:id] }
    @jump_parsec_id_set = JumpLog
      .where(from_parsec_id: sector_parsec_ids)
      .or(JumpLog.where(to_parsec_id: sector_parsec_ids))
      .pluck(:from_parsec_id, :to_parsec_id)
      .flatten
      .to_set & sector_parsec_ids.to_set

    @region_fills_by_hex, @region_labels = helpers.regions_for_map(@sector.parsecs, sector_ul, visible_hx: 1..32, visible_hy: 1..40)

    respond_to do |format|
      format.svg do
        svg = Rails.cache.fetch(cache_key) { render_to_string('sectors/map', formats: [:svg], layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
      format.html do
        svg = Rails.cache.fetch(cache_key) { render_to_string('sectors/map', formats: [:svg], layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
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
