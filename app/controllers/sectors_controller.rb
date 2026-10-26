require 'open3'

class SectorsController < ApplicationController
  include UrlTokenVerification
  include HexMapBases
  include HexMapRogueObjects
  include HexMapOverlays
  include HexMapParsecLabels
  optional_authentication only: %i[map poster]
  before_action :set_sector, except: %i[index new new_from_traveller_map create]

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
    @chart_sectors = Sector.kept.order(:x, :y)

    sector_ids = @sectors.map(&:id)
    @allegiances_by_sector_id = Allegiance
      .joins(star_systems: :parsec)
      .where(parsecs: { sector_id: sector_ids })
      .select('allegiances.id, allegiances.code, allegiances.name, parsecs.sector_id AS sector_id')
      .order('allegiances.code')
      .distinct
      .group_by(&:sector_id)
  end

  def load_defaults
    source = @sector.default_build_source

    unless source
      return redirect_to sector_path(@sector), alert: 'No default build source is configured for this sector.'
    end

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
      redirect_to sector_path(@sector),
                  notice: "#{label} loaded for #{count} #{'subsector'.pluralize(count)}."
    else
      redirect_to sector_path(@sector),
                  alert: "No #{label.downcase} found for this sector."
    end
  end

  def upload_t5
    file = params[:t5_file]
    unless file.present?
      return redirect_to sector_path(@sector), alert: 'Please choose a T5 Tab Delimited file.'
    end

    begin
      parser = T5TabDelimitedParser.parse(file.read)
    rescue T5TabDelimitedParser::InvalidFile => e
      return redirect_to sector_path(@sector), alert: e.message
    end
    plans = parser.build_plans_by_subsector

    count = 0
    @sector.subsectors.each do |subsector|
      plan = plans[subsector.letter]
      next unless plan

      subsector.build = plan
      subsector.build_source = 'uploaded'
      count += 1 if subsector.save
    end

    if count > 0
      redirect_to sector_path(@sector), notice: "T5 defaults loaded for #{count} #{'subsector'.pluralize(count)}."
    else
      redirect_to sector_path(@sector), alert: 'No systems found in the uploaded file.'
    end
  end

  def generate
    subsectors_with_build = @sector.subsectors.where.not(build: nil).where.not(build: '')
    subsectors_with_build = subsectors_with_build.where(id: @sector.ungenerated_subsectors.map(&:id)) if params[:remaining].present?
    subsectors_with_build.each do |subsector|
      GenerateSubsectorJob.set(priority: job_priority(@sector, subsector)).perform_later(subsector.id, subsector.build)
    end
    count = subsectors_with_build.count
    redirect_to sector_path(@sector), notice: "#{helpers.pluralize(count, 'subsector')} queued for generation."
  end

  def import_jump_routes
    metadata = TravellerMap.new.fetch_sector_metadata(@sector.x, @sector.y)

    if metadata.blank?
      redirect_to sector_path(@sector), alert: 'Traveller Map is currently unreachable. Please try again later.'
      return
    end

    stats = SectorRouteImporter.new(@sector, metadata).call
    redirect_to sector_path(@sector),
                notice: "Jump routes imported: #{stats[:links_created]} new link(s), " \
                         "#{stats[:links_skipped_existing]} already existed, " \
                         "#{stats[:entries_skipped_unresolved]} not yet resolvable."
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

    @populated_world_count = @sector.number_of_populated_worlds
    @sector_total_population = @sector.total_population
    @sector_highest_tech_level_code = @sector.highest_tech_level_world&.tech_level_code
    @sector_highest_population_world = @sector.highest_population_world
    @allegiance_count = @sector.get_allegiances.count
    @map_backdrop_url = helpers.sector_map_backdrop_url(@sector)

    position = Sector.kept.where('LOWER(name) < ?', @sector.name.downcase).count + 1
    @page = (position + 9) / 10
    ul = @sector.upper_left
    @starmap_center = [ul.x + 16, ul.y - 20]
  end

  def statistics
    @governments_by_code  = Government.all.index_by(&:code)
    @law_levels_by_code   = LawLevel.all.index_by(&:code)
    @tech_levels_by_code  = TechLevel.all.index_by(&:code)
    @allegiances_by_id    = Allegiance.all.index_by(&:id)
    @travel_zones_by_id   = TravelZone.all.index_by(&:id)
    @facilities_by_id     = Facility.all.index_by(&:id)
    @trade_codes_by_id    = TradeCode.all.index_by(&:id)

    render layout: false
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
    @default_build_source = @sector.default_build_source
    @subsectors = @sector.subsectors.order(:y, :x)
  end

  def map
    @show_map_links = owns_campaign?
    build_survey_overlays_data
    @cols = 32
    @rows = 40
    @compact = params[:compact].present?
    @transparent = params[:transparent].present?
    @subsector_overlays = !@transparent

    @ul = @sector.upper_left

    @star_systems = sector_map_star_systems

    map_version = SectorMapVersion.new(@sector, current_campaign)
    auth_variant = owns_campaign? ? 'auth' : 'public'
    cache_key = "sector_map/#{current_campaign.id}/#{@sector.id}/#{map_version.digest}/#{auth_variant}/#{@compact}/#{@transparent}"

    fresh_when etag: cache_key, last_modified: map_version.last_modified
    return if performed?

    build_sector_map_data

    respond_to do |format|
      format.svg do
        svg = Rails.cache.fetch(cache_key) { render_to_string('shared/hex_map', formats: [:svg], layout: false) }
        enqueue_rasterise(map_version.digest, cache_key) if @compact && @transparent
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
      format.html do
        svg = Rails.cache.fetch(cache_key) { render_to_string('shared/hex_map', formats: [:svg], layout: false) }
        enqueue_rasterise(map_version.digest, cache_key) if @compact && @transparent
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
    end
  end

  # With ?v=<digest>: that exact version, cached for good. Without: the newest image we have
  # (good enough for thumbnails), or a redirect to the SVG, whose render queues the rasterising.
  def map_image
    if params[:v].present?
      version = params[:v].to_s
      return head :not_found unless SectorMapImage.valid_version?(version)

      path = SectorMapImage.new(@sector, version).path
      return head :not_found unless path.exist?

      response.headers['Cache-Control'] = 'private, max-age=31536000, immutable'
    else
      path = SectorMapImage.latest(@sector)
      unless path
        response.headers['Cache-Control'] = 'no-store'
        return redirect_to map_sector_path(@sector, compact: true, transparent: true)
      end

      response.headers['Cache-Control'] = 'private, max-age=300'
    end

    send_file path, type: 'image/webp', disposition: 'inline'
  end

  def poster
    @show_map_links = false
    @poster_mode    = true
    @cols = 32
    @rows = 40
    @subsector_overlays = true
    build_survey_overlays_data

    @ul = @sector.upper_left

    @star_systems = sector_map_star_systems

    build_sector_map_data

    @allegiances_on_poster = @sector.get_allegiances.order(:name)

    @travel_zones_on_poster = TravelZone
      .joins(star_systems: :parsec)
      .where(parsecs: { sector_id: @sector.id })
      .distinct
      .ordered

    @capital_legend_entries = []
    @capital_legend_entries << { label: 'Sector Capital', colour: current_campaign.sector_capital_colour } if current_campaign&.sector_capital_colour.present?
    @capital_legend_entries << { label: 'Subsector Capital', colour: current_campaign.subsector_capital_colour } if current_campaign&.subsector_capital_colour.present?

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
    @jump_route_links_for_map = JumpRouteLink
      .where(from_star_system_id: star_system_subquery, to_star_system_id: star_system_subquery)
      .includes(:jump_route, from_star_system: :parsec, to_star_system: :parsec)
    @jump_routes_on_poster = @jump_route_links_for_map.map(&:jump_route).uniq

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
    @sector.density = SectorBuildSpec::DEFAULT_DENSITY
    @sector.settled = @sector.systems_known = !current_campaign.exploration?
    @sector.max_tech_level = SectorBuildSpec::DEFAULT_MAX_TECH_LEVEL
    @sector.populate_subsectors = true
    @sector.subsector_settings = default_subsector_settings(@sector)
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
    @sector.campaign_slug = current_campaign.slug
    assign_build_options
    # Imported sectors always have their subsectors populated from the Traveller Map data.
    @sector.populate_subsectors = true if @sector.source == 'traveller_map'

    if params[:t5_file].present? && (@sector.creation_mode == 't5' || build_option_params.empty?)
      begin
        parser = T5TabDelimitedParser.parse(params[:t5_file].read)
        if parser.systems.present?
          survey_index = extract_survey_index(@sector.default_build_spec)
          @sector.t5_build_specs = parser.build_plans_by_subsector(survey_index: survey_index)
        end
      rescue T5TabDelimitedParser::InvalidFile => e
        flash.now[:alert] = e.message
        return render :new, status: :unprocessable_entity
      end
    end

    if @sector.creation_mode == 't5' && @sector.t5_build_specs.blank?
      flash.now[:alert] = 'Please choose a T5 Tab Delimited file containing systems.'
      return render :new, status: :unprocessable_entity
    end

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
    def enqueue_rasterise(version, svg_cache_key)
      return if SectorMapImage.new(@sector, version).exist?
      return unless Rails.cache.write("sector_map_raster/#{@sector.id}/#{version}", true, unless_exist: true, expires_in: 10.minutes)

      RasteriseSectorMapJob.perform_later(@sector.id, version, svg_cache_key)
    end

    # Main worlds and stars are preloaded without their bulky text/jsonb columns (build log,
    # characteristics, notes): the map never reads them and they made that one query
    # take seconds on a full sector.
    MAP_EXCLUDED_COLUMNS = %w[build_log characteristics player_notes referee_notes].freeze

    def sector_map_star_systems
      systems = StarSystem
        .joins(:parsec)
        .where(parsecs: { sector_id: @sector.id })
        .includes({ parsec: { sector: :subsectors } }, :allegiance)
        .load
      lean = StellarObject.select(StellarObject.column_names - MAP_EXCLUDED_COLUMNS)
      preload_with(systems.to_a, :stars, lean)
      preload_with(systems.to_a, :main_world, lean)
      preload_with(systems.filter_map(&:main_world), :trade_codes, TradeCode.all)
      preload_with(systems.flat_map(&:stars), :companion, lean)
      systems
    end

    def preload_with(records, associations, scope)
      ActiveRecord::Associations::Preloader.new(records: records, associations: associations, scope: scope).call
    end

    def build_sector_map_data
      sector_ul = @ul

      @systems_by_pos = @star_systems.each_with_object({}) do |sys, h|
        col = sys.parsec.x - sector_ul.x + 1
        row = sector_ul.y - sys.parsec.y + 1
        h[[col, row]] = sys
      end
      build_bases_data

      @parsecs_by_pos = build_parsecs_by_pos(@sector.parsecs, sector_ul)
      @map_label_icons = build_parsec_label_icons(@parsecs_by_pos)

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
        @sector.parsecs, sector_ul, visible_col: 1..32, visible_row: 1..40, authenticated: owns_campaign?
      )

      rogue_data = StellarObject
        .where(parsec_id: sector_parsec_subquery, orbiting_id: nil)
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

      build_rogue_objects_data(sector_parsec_subquery)

      star_system_subquery = @star_systems.select(:id)
      @jump_route_links_for_map = JumpRouteLink
        .where(from_star_system_id: star_system_subquery, to_star_system_id: star_system_subquery)
        .includes(:jump_route, from_star_system: :parsec, to_star_system: :parsec)
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_sector
      @sector = Sector.kept.find(params.expect(:id))
      @sector.campaign_slug = current_campaign&.slug
    end

    # Only allow a list of trusted parameters through.
    def sector_params
      params.expect(sector: [:name, :x, :y, :abbreviation, :player_notes, :referee_notes, :build, :source, :language, :default_build_spec, :reference_url])
    end

    def build_option_params
      params.fetch(:sector, {}).permit(:density, :settled, :systems_known, :max_tech_level, :populate_subsectors, :creation_mode)
    end

    # The new sector form offers a few simple choices rather than raw YAML; turn them
    # into the default build specification applied to every subsector.
    def assign_build_options
      options = build_option_params
      boolean = ActiveModel::Type::Boolean.new
      @sector.density = options[:density].presence || SectorBuildSpec::DEFAULT_DENSITY
      @sector.settled = boolean.cast(options[:settled]) || false
      @sector.systems_known = boolean.cast(options[:systems_known]) || false
      @sector.max_tech_level = SectorBuildSpec.normalise_max_tech_level(options[:max_tech_level])
      @sector.populate_subsectors = boolean.cast(options[:populate_subsectors]) || false
      @sector.creation_mode = CREATION_MODES.include?(options[:creation_mode]) ? options[:creation_mode] : 'options'
      @sector.subsector_settings = subsector_settings_from_params if @sector.creation_mode == 'subsectors'
      return if options.empty? && @sector.default_build_spec.present?

      @sector.default_build_spec = SectorBuildSpec.to_yaml(
        density: @sector.density, known: @sector.systems_known, settled: @sector.settled,
        max_tech_level: @sector.max_tech_level
      )
    end

    CREATION_MODES = %w[options subsectors t5].freeze
    SUBSECTOR_LETTERS = ('A'..'P').to_a.freeze

    def default_subsector_settings(sector)
      SUBSECTOR_LETTERS.index_with do |letter|
        { name: letter, density: sector.density, settled: sector.settled, known: sector.systems_known,
          max_tech_level: sector.max_tech_level }
      end
    end

    # Per-subsector rows from the customise grid, keyed by subsector letter.
    def subsector_settings_from_params
      boolean = ActiveModel::Type::Boolean.new
      rows = params.fetch(:subsectors, {}).permit(SUBSECTOR_LETTERS.index_with { %i[name density settled known max_tech_level] })
      defaults = default_subsector_settings(@sector)

      SUBSECTOR_LETTERS.index_with do |letter|
        row = rows[letter] || {}
        {
          name: row[:name].to_s.strip.presence || letter,
          density: row[:density].presence || defaults[letter][:density],
          settled: boolean.cast(row[:settled]) || false,
          known: boolean.cast(row[:known]) || false,
          max_tech_level: SectorBuildSpec.normalise_max_tech_level(row[:max_tech_level])
        }
      end
    end

    def job_priority(sector, subsector)
      sector.x.abs * 1000 + sector.y.abs * 10 +  subsector.y + subsector.x
    end

    def extract_survey_index(yaml_text)
      YAML.safe_load(yaml_text.to_s, permitted_classes: [], permitted_symbols: [], aliases: false)&.dig('defaultSI')
    rescue Psych::SyntaxError
      nil
    end
end
