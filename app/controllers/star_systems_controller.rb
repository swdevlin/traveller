require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'vips'

class StarSystemsController < ApplicationController
  include ParentHex
  before_action :set_star_system, only: %i[ show edit update destroy map ]
  before_action :set_form_context

  # GET /star_systems or /star_systems.json
  def index
    @star_systems = StarSystem.all
  end

  # GET /star_systems/1 or /star_systems/1.json
  def show
    @primary = @star_system.primary_star
    @orbiting_bodies = @star_system.orbiting_bodies
  end

  # GET /star_systems/1/map.svg or .webp
  def map
    fresh_when @star_system
    return if performed?

    respond_to do |format|
      format.svg  { send_data cached_svg, type: 'image/svg+xml', disposition: 'inline' }
      format.html { send_data cached_svg, type: 'image/svg+xml', disposition: 'inline' }
      format.webp { send_data cached_webp, type: 'image/webp', disposition: 'inline' }
    end
  end

  # GET /star_systems/new
  def new
    @star_system = StarSystem.new

    @star_system.parsec_id = @parsec.id if @parsec

    @return_to = request.referer
  end

  # GET /star_systems/1/edit
  def edit
  end

  # POST /star_systems or /star_systems.json
  def create
    create_params = new_star_system_params

    @star_system = case create_params[:create_mode]
    when 'empty'
      create_empty_star_system(create_params)
    when 'random'
      generate_random_star_system(create_params)
    when 'build_configuration'
      generate_build_configuration_star_system(create_params)
    else
      StarSystem.new.tap { |s| s.errors.add(:base, 'Invalid create mode') }
    end

    if @star_system.errors.any?
      if @star_system.errors[:base].any?
        message = @star_system.errors.full_messages_for(:base).to_sentence
        flash.now[:alert] = [flash.now[:alert], message].compact.join(' ')
      end

      return render :new, status: :unprocessable_entity
    end

    redirect_to @star_system, notice: 'Star system created.'
  end

  # PATCH/PUT /star_systems/1 or /star_systems/1.json
  def update
    respond_to do |format|
      if @star_system.update(star_system_edit_params)
        format.html { redirect_to @star_system, notice: 'Star system was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @star_system }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @star_system.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /star_systems/1 or /star_systems/1.json
  def destroy
    @star_system.destroy!

    respond_to do |format|
      format.html { redirect_to star_systems_path, notice: 'Star system was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def cached_svg
    Rails.cache.fetch("system_map_svg/#{@star_system.cache_key_with_version}") do
      render_to_string(formats: [:svg], layout: false)
    end
  end

  def cached_webp
    Rails.cache.fetch("system_map_webp/#{@star_system.cache_key_with_version}") do
      image = Vips::Image.new_from_buffer(cached_svg, '')
      image.webpsave_buffer
    end
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_star_system
    @star_system = StarSystem.find(params.expect(:id))
  end

  def create_empty_star_system(params)
    spectral_type = params['primary_spectral_type']
    dwarf_type = %w[BD D].include?(spectral_type)

    if spectral_type.blank? || (!dwarf_type && (params['primary_spectral_subtype'].blank? || params['primary_luminosity'].blank?))
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, 'Spectral type, subtype, and luminosity class must all be provided')
      end
    end

    primary = if dwarf_type
      { 'type' => spectral_type }
    else
      {
        'type' => "#{spectral_type}#{params['primary_spectral_subtype']}",
        'class' => params['primary_luminosity']
      }
    end

    build_config = {
      'name' => params['name'],
      'counts' => {
        'gasGiants' => 0,
        'planetoidBelts' => 0,
        'terrestrialPlanets' => 0
      },
      'primary' => primary
    }
    result = GeneratorService.new.generate_star_system(build_config)

    unless result.success?
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, result.errors.to_sentence)
      end
    end
    payload = result.value

    importer = StarSystemImporter.new
    @parsec ||= Parsec.find(star_system_params[:parsec_id])
    importer.import!(@parsec, payload)
  rescue ActiveRecord::RecordInvalid => e
    e.record
  end

  def generate_build_configuration_star_system(params)
    build_yaml = params['build_configuration']
    validator = BuildConfigValidator.new(build_yaml)

    unless validator.valid_for_star_system?
      @build_errors = validator.errors
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:build_configuration, 'Invalid build specification')
      end
    end

    config =
      YAML.safe_load(
        build_yaml,
        permitted_classes: [Date, Time], # add more if you truly need them
        aliases: false
      ) || {}

    result = GeneratorService.new.generate_star_system(config)

    unless result.success?
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, result.errors.to_sentence)
      end
    end
    payload = result.value

    importer = StarSystemImporter.new
    @parsec ||= Parsec.find(star_system_params[:parsec_id])
    importer.import!(@parsec, payload)
  rescue ActiveRecord::RecordInvalid => e
    e.record

    StarSystem.new.tap { |s| s.errors.add(:base, 'Build configuration mode is not yet implemented') }
  end

  def generate_random_star_system(params)
    build_config = {
      'name' => params['name']
    }
    result = GeneratorService.new.generate_star_system(build_config)

    unless result.success?
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, result.errors.to_sentence)
      end
    end
    payload = result.value

    importer = StarSystemImporter.new
    @parsec ||= Parsec.find(star_system_params[:parsec_id])
    importer.import!(@parsec, payload)
  rescue ActiveRecord::RecordInvalid => e
    e.record
  end

  def star_system_edit_params
    params.expect(star_system: [:name, :notes])
  end

  def new_star_system_params
    params.expect(star_system: [:name, :parsec_id, :create_mode, :build_configuration, :primary_spectral_type, :primary_spectral_subtype, :primary_luminosity])
  end

  def star_system_params
    params.expect(star_system: [:name, :parsec_id, :notes])
  end

  def star_generator_params
    permitted = [:random_star]
    %w[primary primary_companion close close_companion near near_companion far far_companion].each do |prefix|
      permitted << "#{prefix}_enabled".to_sym unless prefix == 'primary'
      permitted << "#{prefix}_spectral_type".to_sym
      permitted << "#{prefix}_spectral_subtype".to_sym
      permitted << "#{prefix}_luminosity".to_sym
    end
    params.require(:star_system).permit(*permitted)
  end

  def star_generate_params_errors
    sp = star_generator_params

    # Validate primary star (required)
    error = validate_star_params(sp, 'primary', required: true)
    return error if error

    # Validate optional stars and their companions
    %w[close near far].each do |orbit|
      if sp["#{orbit}_enabled"] == '1'
        error = validate_star_params(sp, orbit, required: true)
        return error if error
      end

      if sp["#{orbit}_companion_enabled"] == '1'
        error = validate_star_params(sp, "#{orbit}_companion", required: true)
        return error if error
      end
    end

    # Validate primary companion
    if sp['primary_companion_enabled'] == '1'
      error = validate_star_params(sp, 'primary_companion', required: true)
      return error if error
    end

    nil
  end

  def build_star_definition(sp, prefix)
    {
      type: "#{sp["#{prefix}_spectral_type"]}#{sp["#{prefix}_spectral_subtype"]}",
      class: sp["#{prefix}_luminosity"]
    }
  end

  def spectral_type_valid(type)
    spectral_type_options.any? { |a| a.second == type }
  end

  def validate_star_params(sp, prefix, required: false)
    type_key = "#{prefix}_spectral_type"
    subtype_key = "#{prefix}_spectral_subtype"
    luminosity_key = "#{prefix}_luminosity"

    fields = { type_key => sp[type_key], subtype_key => sp[subtype_key], luminosity_key => sp[luminosity_key] }
    missing = fields.select { |_, v| v.blank? }.keys

    if required && missing.any?
      label = prefix.titleize
      return "#{label}: spectral type, subtype, and luminosity must all be provided"
    end

    return nil if missing.size == 3 # All blank is OK for optional stars

    spectral_type = sp[type_key]
    luminosity = sp[luminosity_key]
    subtype = sp[subtype_key].to_i

    return "#{prefix.titleize}: #{spectral_type} not valid." unless spectral_type_valid(spectral_type)

    if %w[O M].include?(spectral_type) && luminosity == 'IV'
      return "#{prefix.titleize}: #{spectral_type} IV stars are not supported by the generator."
    end
    if %w[A F].include?(spectral_type) && luminosity == 'VI'
      return "#{prefix.titleize}: #{spectral_type} VI stars are not supported by the generator."
    end
    if spectral_type == 'K' && subtype >= 5 && luminosity == 'VI'
      return "#{prefix.titleize}: K#{subtype} VI stars are not supported by the generator."
    end

    nil
  end

  def spectral_type_options
    types = %w[O B A F G K M].map { |t| [t, t] }
    types << ['Brown Dwarf', 'BD']
    types << ['White Dwarf', 'D']
  end

  def set_form_context
    @submit_label = action_name == 'edit' ? 'Save changes' : 'Add star system'

    @form_url =
      if request.path.include?('/parsecs/')
        parsec_star_systems_path(@parsec)
      else
        polymorphic_path([@subsector || @sector, :star_systems])
      end

    @spectral_type_options = spectral_type_options

    @spectral_subtype_options = (0..9).map { |n| [n.to_s, n] }

    @luminosity_options = [
      ['0 (Hypergiant)', '0'],
      ['Ia (Luminous supergiant)', 'Ia'],
      ['Iab (Intermediate supergiant)', 'Iab'],
      ['Ib (Less luminous supergiant)', 'Ib'],
      ['II (Bright giant)', 'II'],
      ['III (Giant)', 'III'],
      ['IV (Subgiant)', 'IV'],
      ['V (Main sequence)', 'V'],
      ['VI (Subdwarf)', 'VI'],
      ['VII (White dwarf)', 'VII']
    ]
  end
end
