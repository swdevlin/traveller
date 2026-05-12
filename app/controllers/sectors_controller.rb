require 'open3'

class SectorsController < ApplicationController
  include UrlTokenVerification
  include HexMapBases
  optional_authentication only: %i[map poster]
  before_action :set_sector, only: %i[ show edit update destroy clear load_defaults populate generate defaults_source map poster ]

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
        GenerateSubsectorJob.set(priority: job_priority(@sector, subsector)).perform_later(subsector.id, subsector.build)
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
    ul = @sector.upper_left
    @starmap_center = [ul.x + 16, ul.y - 20]
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
    @show_map_links = authenticated?
    @native_sophont_colour  = current_campaign.show_native_sophont?  ? current_campaign.native_sophont_colour.presence  : nil
    @extinct_sophont_colour = current_campaign.show_extinct_sophont? ? current_campaign.extinct_sophont_colour.presence : nil
    @cols = 32
    @rows = 40
    @subsector_overlays = true

    @ul = @sector.upper_left

    @star_systems = StarSystem
      .joins(:parsec)
      .where(parsecs: { sector_id: @sector.id })
      .includes(:parsec, :allegiance, :main_world, stars: [:companion])

    max_updated = @star_systems.maximum(:updated_at)
    max_parsec_updated = @sector.parsecs.maximum(:updated_at)
    region_parsec_max = RegionParsec.joins(:parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    region_record_max = Region.joins(region_parsecs: :parsec).where(parsecs: { sector_id: @sector.id }).maximum(:updated_at)
    region_max_updated = [region_parsec_max, region_record_max].compact.max
    jump_max_updated = JumpLog.maximum(:updated_at)
    rogue_max_updated = StellarObject
      .where(parsec: @sector.parsecs, orbiting_id: nil)
      .where(type: %w[GasGiant Comet])
      .maximum(:updated_at)
    facility_max_updated = StarSystemFacility
      .joins(star_system: :parsec)
      .where(parsecs: { sector_id: @sector.id })
      .maximum(:updated_at)
    auth_variant = authenticated? ? 'auth' : 'public'
    sophont_variant = "#{current_campaign.show_native_sophont?}-#{@native_sophont_colour}-#{current_campaign.show_extinct_sophont?}-#{@extinct_sophont_colour}"
    cache_key = "sector_map/#{current_campaign.id}/#{@sector.id}/#{@sector.updated_at.to_i}-#{max_updated.to_i}-#{max_parsec_updated.to_i}-#{region_max_updated.to_i}-#{jump_max_updated.to_i}-#{rogue_max_updated.to_i}-#{facility_max_updated.to_i}/#{auth_variant}/#{sophont_variant}"

    fresh_when etag: cache_key, last_modified: [@sector.updated_at, max_updated, max_parsec_updated, region_max_updated, jump_max_updated].compact.max
    return if performed?

    build_sector_map_data

    respond_to do |format|
      format.svg do
        svg = Rails.cache.fetch(cache_key) { render_to_string('shared/hex_map', formats: [:svg], layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
      format.html do
        svg = Rails.cache.fetch(cache_key) { render_to_string('shared/hex_map', formats: [:svg], layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
    end
  end

  def poster
    @show_map_links = false
    @poster_mode    = true
    @cols = 32
    @rows = 40
    @subsector_overlays = true
    @native_sophont_colour  = current_campaign.show_native_sophont?  ? current_campaign.native_sophont_colour.presence  : nil
    @extinct_sophont_colour = current_campaign.show_extinct_sophont? ? current_campaign.extinct_sophont_colour.presence : nil

    @ul = @sector.upper_left

    @star_systems = StarSystem
      .joins(:parsec)
      .where(parsecs: { sector_id: @sector.id })
      .includes(:parsec, :allegiance, :main_world, stars: [:companion])

    build_sector_map_data

    neighbours = @sector.neighbours

    coreward_sector = neighbours[[@sector.x,     @sector.y + 1]]
    rimward_sector  = neighbours[[@sector.x,     @sector.y - 1]]
    spinward_sector = neighbours[[@sector.x - 1, @sector.y]]
    trailing_sector = neighbours[[@sector.x + 1, @sector.y]]

    @coreward_subsectors = coreward_sector&.subsectors&.where(y: 4)&.order(:x)&.to_a || []
    @rimward_subsectors  = rimward_sector&.subsectors&.where(y: 1)&.order(:x)&.to_a  || []
    @spinward_subsectors = spinward_sector&.subsectors&.where(x: 4)&.order(:y)&.to_a || []
    @trailing_subsectors = trailing_sector&.subsectors&.where(x: 1)&.order(:y)&.to_a || []

    star_system_subquery = StarSystem.joins(:parsec).where(parsecs: { sector_id: @sector.id }).select(:id)
    @network_links_for_map = NetworkLink
      .where(from_star_system_id: star_system_subquery, to_star_system_id: star_system_subquery)
      .includes(:network, from_star_system: :parsec, to_star_system: :parsec)
    @networks_on_poster = @network_links_for_map.map(&:network).uniq

    @hex_map_svg = render_to_string('shared/hex_map', formats: [:svg], layout: false)

    poster_svg = render_to_string('sectors/poster', formats: [:svg], layout: false)
    pdf_data, status = Open3.capture2('rsvg-convert', '-f', 'pdf', stdin_data: poster_svg)
    raise 'rsvg-convert failed' unless status.success?

    send_data pdf_data,
              type: 'application/pdf',
              disposition: 'attachment',
              filename: "#{@sector.name.parameterize}-sector-poster.pdf"
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
    DeleteSectorJob.perform_later(@sector.id)

    respond_to do |format|
      format.html { redirect_to sectors_path, notice: 'Sector deleted.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    def build_sector_map_data
      sector_ul = @ul

      @systems_by_pos = @star_systems.each_with_object({}) do |sys, h|
        col = sys.parsec.x - sector_ul.x + 1
        row = sector_ul.y - sys.parsec.y + 1
        h[[col, row]] = sys
      end
      build_bases_data

      @parsecs_by_pos = @sector.parsecs.pluck(:id, :x, :y, :label, :label_colour).to_h do |pid, px, py, lbl, label_colour|
        col = px - sector_ul.x + 1
        row = sector_ul.y - py + 1
        [[col, row], { id: pid, hex_code: format('%02d%02d', col, row), label: lbl, label_colour: label_colour }]
      end

      sector_parsec_ids = @parsecs_by_pos.values.map { |v| v[:id] }
      sector_parsec_subquery = @sector.parsecs.select(:id)

      jump_parsec_ids = JumpLog
        .where(from_parsec_id: sector_parsec_subquery)
        .or(JumpLog.where(to_parsec_id: sector_parsec_subquery))
        .pluck(:from_parsec_id, :to_parsec_id)
        .flatten
        .to_set & sector_parsec_ids.to_set

      parsec_id_to_pos = @parsecs_by_pos.each_with_object({}) { |(pos, data), h| h[data[:id]] = pos }
      @jump_highlight_positions = jump_parsec_ids.filter_map { |pid| parsec_id_to_pos[pid] }.to_set

      @region_fills_by_pos, @region_labels, @region_borders = helpers.regions_for_map(
        @sector.parsecs, sector_ul, visible_col: 1..32, visible_row: 1..40, authenticated: authenticated?
      )

      rogue_data = StellarObject
        .where(parsec: @sector.parsecs, orbiting_id: nil)
        .where(type: %w[GasGiant Comet])
        .pluck(:parsec_id, :type)
      @rogues_by_pos = rogue_data.each_with_object({}) do |(pid, t), h|
        pos = parsec_id_to_pos[pid]
        next unless pos
        h[pos] ||= Set.new
        h[pos] << t
      end.transform_values do |types|
        ordered = []
        ordered << :gas_giant if types.include?('GasGiant')
        ordered << :comet     if types.include?('Comet')
        ordered
      end
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_sector
      @sector = Sector.kept.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def sector_params
      params.expect(sector: [:name, :x, :y, :abbreviation, :notes, :build, :source])
    end

    def job_priority(sector, subsector)
      sector.x.abs * 1000 + sector.y.abs * 10 +  subsector.y + subsector.x
    end
end
