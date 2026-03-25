class SubsectorsController < ApplicationController
  include UrlTokenVerification
  optional_authentication only: [:map]
  before_action :set_subsector, only: %i[ show edit update clear load_defaults populate generate star_systems_table map]
  before_action :set_counts, only: %i[show populate]
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
    render layout: false
  end

  def map
    @show_map_links = authenticated?
    @star_systems = @subsector.star_systems.includes(:parsec, :allegiance, stars: [])
    if params[:highlight].present?
      highlighted_parsec = Parsec.find_by(id: params[:highlight])
      @highlight_hex = highlighted_parsec&.hex_code
    end

    sector_ul = @subsector.sector.upper_left
    @parsec_ids_by_hex = @subsector.parsecs.pluck(:id, :x, :y, :label, :label_colour).to_h do |pid, px, py, lbl, colour|
      hx = px - sector_ul.x + 1
      hy = sector_ul.y - py + 1
      [format('%02d%02d', hx, hy), { id: pid, label: lbl, colour: colour }]
    end

    @compact = params[:compact].present?

    max_updated = @star_systems.maximum(:updated_at)
    max_parsec_updated = @subsector.parsecs.maximum(:updated_at)
    subsector_parsecs = @subsector.parsecs
    region_parsec_max = RegionParsec.where(parsec_id: subsector_parsecs).maximum(:updated_at)
    region_record_max = Region.joins(region_components: :region_parsecs).where(region_parsecs: { parsec_id: subsector_parsecs }).maximum(:updated_at)
    region_max_updated = [region_parsec_max, region_record_max].compact.max
    jump_max_updated = JumpLog.maximum(:updated_at)
    auth_variant = authenticated? ? 'auth' : 'public'
    version = Digest::SHA256.hexdigest([
      @subsector.updated_at.to_i,
      max_updated.to_i,
      max_parsec_updated.to_i,
      region_max_updated.to_i,
      jump_max_updated.to_i,
      current_campaign.updated_at.to_i
    ].join('-'))
    cache_key = "subsector_map/#{current_campaign.id}/#{@subsector.id}/#{@highlight_hex}/#{@compact}/#{version}/#{auth_variant}"

    @native_sophont_colour  = current_campaign.native_sophont_colour.presence
    @extinct_sophont_colour = current_campaign.extinct_sophont_colour.presence

    fresh_when etag: cache_key, last_modified: [@subsector.updated_at, max_updated, max_parsec_updated, region_max_updated, jump_max_updated].compact.max
    return if performed?

    sub = @subsector
    subsector_parsec_ids = @parsec_ids_by_hex.values.map { |v| v[:id] }
    @jump_parsec_id_set = JumpLog
      .where(from_parsec_id: subsector_parsec_ids)
      .or(JumpLog.where(to_parsec_id: subsector_parsec_ids))
      .pluck(:from_parsec_id, :to_parsec_id)
      .flatten
      .to_set & subsector_parsec_ids.to_set

    @region_fills_by_hex, @region_labels = helpers.regions_for_map(
      subsector_parsecs,
      sector_ul,
      visible_hx: ((sub.x - 1) * 8 + 1)..(sub.x * 8),
      visible_hy: ((sub.y - 1) * 10 + 1)..(sub.y * 10)
    )

    respond_to do |format|
      format.svg do
        svg = Rails.cache.fetch(cache_key) { render_to_string('subsectors/map', formats: [:svg], layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
      format.html do
        svg = Rails.cache.fetch(cache_key) { render_to_string('subsectors/map', formats: [:svg], layout: false) }
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
