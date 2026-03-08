class SubsectorsController < ApplicationController
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
    @subsector.save!
    GenerateSubsectorJob.perform_later(@subsector, normalized_yaml)
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
    @star_systems = @subsector.star_systems.includes(:parsec, :allegiance, stars: [])
    if params[:highlight].present?
      highlighted_parsec = Parsec.find_by(id: params[:highlight])
      @highlight_hex = highlighted_parsec&.hex_code
    end

    sector_ul = @subsector.sector.upper_left
    @parsec_ids_by_hex = @subsector.parsecs.pluck(:id, :x, :y).to_h do |pid, px, py|
      hx = px - sector_ul.x + 1
      hy = sector_ul.y - py + 1
      [format('%02d%02d', hx, hy), pid]
    end

    @compact = params[:compact].present?

    max_updated = @star_systems.maximum(:updated_at)
    cache_key = "subsector_map/#{@subsector.id}/#{@highlight_hex}/#{@compact}/#{@subsector.updated_at.to_i}-#{max_updated.to_i}"

    fresh_when etag: cache_key, last_modified: [@subsector.updated_at, max_updated].compact.max
    return if performed?

    respond_to do |format|
      format.svg do
        svg = Rails.cache.fetch(cache_key) { render_to_string(layout: false) }
        send_data svg, type: 'image/svg+xml', disposition: 'inline'
      end
      format.html do
        svg = Rails.cache.fetch(cache_key) { render_to_string(layout: false, content_type: 'image/svg+xml') }
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
        @subsector.errors.add(:build, validator.errors.join(', '))
        respond_to do |format|
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @subsector.errors, status: :unprocessable_entity }
        end
        return
      end
      params_to_save[:build] = normalize_build_yaml(build_yaml)
    end

    respond_to do |format|
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
