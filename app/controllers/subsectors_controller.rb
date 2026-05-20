class SubsectorsController < ApplicationController
  include UrlTokenVerification
  include HexMapBases
  optional_authentication only: [:map]
  before_action :set_subsector, except: :index
  before_action :set_counts, only: %i[show populate]
  # GET /subsectors or /subsectors.json
  def index
    @subsectors = Subsector.all
  end

  # GET /subsectors/1 or /subsectors/1.json
  def show
    ul, = @subsector.universal_coordinates
    @starmap_center = [ul.x + 4, ul.y - 5]
    @star_systems = @subsector.star_systems.includes(:parsec, :allegiance, :travel_zone, :main_world, stars: [])
  end

  # GET /subsectors/1/edit
  def edit
  end

  def populate
    unless @subsector.build.present?
      populate_build_from_template!
    end
  end

  def generate
    build_yaml = subsector_generate_params[:build]
    validator = BuildConfigValidator.new(build_yaml)

    unless validator.valid?
      @build_yaml = build_yaml
      @build_errors = validator.errors

      flash.now[:alert] = "Invalid build configuration (#{@build_errors.size} issues)."
      render :populate, status: :unprocessable_entity and return
    end

    normalized_yaml = normalize_build_yaml(build_yaml)
    @subsector.build = normalized_yaml
    @subsector.build_source ||= 'default'
    @subsector.save!
    GenerateSubsectorJob.perform_later(@subsector.id, normalized_yaml)
    redirect_to subsector_path(@subsector), notice: 'Subsector population task created.'
  end

  def load_defaults
    @subsector.load_travellermap_defaults!
    if @subsector.build.present? && @subsector.save
      redirect_to subsector_path(@subsector), notice: 'Defaults loaded.'
    else
      redirect_to subsector_path(@subsector), alert: 'No defaults found for this sector.'
    end
  end

  def star_systems_table
    @star_systems = @subsector.star_systems.includes(:parsec, :allegiance, :travel_zone, :main_world, stars: [])
    render layout: false
  end

  def map
    @show_map_links = authenticated?
    @star_systems = @subsector.star_systems.includes(:parsec, :allegiance, :travel_zone, stars: [])

    @cols = 8
    @rows = 10

    sector_ul = @subsector.sector.upper_left
    sub_ul, _sub_lr = sector_ul.subsector_corners(@subsector)
    @ul = sub_ul

    if params[:highlight].present?
      highlighted_parsec = Parsec.find_by(id: params[:highlight])
      @highlight_hex = highlighted_parsec&.hex_code
      if highlighted_parsec
        hcol = highlighted_parsec.x - sub_ul.x + 1
        hrow = sub_ul.y - highlighted_parsec.y + 1
        @highlight_pos = [hcol, hrow] if (1..8).cover?(hcol) && (1..10).cover?(hrow)
      end
    end

    @compact = params[:compact].present?

    max_updated = @star_systems.maximum(:updated_at)
    max_parsec_updated = @subsector.parsecs.maximum(:updated_at)
    subsector_parsecs = @subsector.parsecs
    region_parsec_max = RegionParsec.where(parsec_id: subsector_parsecs).maximum(:updated_at)
    region_record_max = Region.joins(:region_parsecs).where(region_parsecs: { parsec_id: subsector_parsecs }).maximum(:updated_at)
    region_max_updated = [region_parsec_max, region_record_max].compact.max
    jump_max_updated = JumpLog.maximum(:updated_at)
    star_system_subquery = @subsector.star_systems_scope.select(:id)
    network_link_max_updated = NetworkLink
      .where(from_star_system_id: star_system_subquery)
      .or(NetworkLink.where(to_star_system_id: star_system_subquery))
      .maximum(:updated_at)
    rogue_max_updated = StellarObject
      .where(parsec: @subsector.parsecs, orbiting_id: nil)
      .where(type: %w[GasGiant Comet])
      .maximum(:updated_at)
    facility_max_updated = StarSystemFacility
      .where(star_system_id: star_system_subquery)
      .maximum(:updated_at)
    auth_variant = authenticated? ? 'auth' : 'public'
    version = Digest::SHA256.hexdigest([
      @subsector.updated_at.to_i,
      max_updated.to_i,
      max_parsec_updated.to_i,
      region_max_updated.to_i,
      jump_max_updated.to_i,
      network_link_max_updated.to_i,
      rogue_max_updated.to_i,
      facility_max_updated.to_i,
      current_campaign.updated_at.to_i,
      MAP_TEMPLATE_VERSION
    ].join('-'))
    cache_key = "subsector_map/#{current_campaign.id}/#{@subsector.id}/#{@highlight_hex}/#{@compact}/#{version}/#{auth_variant}"

    @native_sophont_colour  = current_campaign.native_sophont_colour.presence
    @extinct_sophont_colour = current_campaign.extinct_sophont_colour.presence

    fresh_when etag: cache_key, last_modified: [@subsector.updated_at, max_updated, max_parsec_updated, region_max_updated, jump_max_updated, network_link_max_updated].compact.max
    return if performed?

    @parsecs_by_pos = @subsector.parsecs.pluck(:id, :x, :y, :label, :label_colour).to_h do |pid, px, py, lbl, label_colour|
      col = px - sub_ul.x + 1
      row = sub_ul.y - py + 1
      hex_code = format('%02d%02d', px - sector_ul.x + 1, sector_ul.y - py + 1)
      [[col, row], { id: pid, hex_code: hex_code, label: lbl, label_colour: label_colour }]
    end

    @systems_by_pos = @star_systems.each_with_object({}) do |sys, h|
      col = sys.parsec.x - sub_ul.x + 1
      row = sub_ul.y - sys.parsec.y + 1
      h[[col, row]] = sys
    end
    build_bases_data

    subsector_parsec_ids = @parsecs_by_pos.values.map { |v| v[:id] }
    subsector_parsec_subquery = @subsector.parsecs.select(:id)

    jump_parsec_ids = JumpLog
      .where(from_parsec_id: subsector_parsec_subquery)
      .or(JumpLog.where(to_parsec_id: subsector_parsec_subquery))
      .pluck(:from_parsec_id, :to_parsec_id)
      .flatten
      .to_set & subsector_parsec_ids.to_set

    parsec_id_to_pos = @parsecs_by_pos.each_with_object({}) { |(pos, data), h| h[data[:id]] = pos }
    @jump_highlight_positions = jump_parsec_ids.filter_map { |pid| parsec_id_to_pos[pid] }.to_set

    @network_links_for_map = NetworkLink
      .where(from_star_system_id: star_system_subquery)
      .or(NetworkLink.where(to_star_system_id: star_system_subquery))
      .includes(:network, from_star_system: :parsec, to_star_system: :parsec)

    @region_fills_by_pos, @region_labels, @region_borders = helpers.regions_for_map(
      subsector_parsecs,
      sub_ul,
      visible_col: 1..8,
      visible_row: 1..10,
      authenticated: authenticated?
    )

    rogue_data = StellarObject
      .where(parsec: @subsector.parsecs, orbiting_id: nil)
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

  def clear
    Subsector.transaction do
      @subsector.clear
    end
    redirect_to subsector_path(@subsector), notice: 'Subsector cleared.'
  end


  # PATCH/PUT /subsectors/1 or /subsectors/1.json
  def update
    params_to_save = subsector_params.to_h
    build_yaml = params_to_save[:build]

    if build_yaml.blank?
      params_to_save[:build] = nil
    else
      validator = BuildConfigValidator.new(build_yaml)
      unless validator.valid?
        @subsector.assign_attributes(params_to_save)
        validator.errors.each { |e| @subsector.errors.add(:build, e) }
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @subsector.errors, status: :unprocessable_entity }
        end
        return
      end
      params_to_save[:build] = normalize_build_yaml(build_yaml)
    end

    respond_to do |format|
      if params_to_save.key?(:build) && params_to_save[:build] != @subsector.build
        params_to_save[:build_source] = 'homebrew'
      end

      if @subsector.update(params_to_save)
        format.html { redirect_to @subsector, notice: 'Subsector was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @subsector }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @subsector.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_counts
    @star_system_count = @subsector.star_systems.count
    @rogue_count = @subsector.rogues.count
    @populated_system_count = @subsector.number_of_populated_star_systems
  end

  def set_subsector
    @subsector = Subsector.find(params.expect(:id))
  end

  def subsector_params
    params.expect(subsector: [:name, :x, :y, :notes, :build])
  end

  def subsector_generate_params
    params.expect(subsector: [:build])
  end

  def populate_build_from_template!
    path = Rails.root.join('app', 'templates', 'subsectors', 'build_template.yml.erb')
    erb  = ERB.new(path.read)

    @subsector.build = erb.result_with_hash({})
  end

  def normalize_build_yaml(yaml_string)
    config = YAML.safe_load(yaml_string, permitted_classes: [], permitted_symbols: [], aliases: false)
    return yaml_string unless config.is_a?(Hash)

    config['type'] = config['type'].upcase if config['type'].is_a?(String)
    YAML.dump(config)
  end
end
