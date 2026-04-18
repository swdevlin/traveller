require 'net/http'
require 'uri'
require 'json'
require 'yaml'
require 'vips'

class StarSystemsController < ApplicationController
  include ParentHex
  include UrlTokenVerification
  include LinkModalSetup
  optional_authentication only: [:map]
  before_action :set_star_system, only: %i[ show edit update destroy map select_main_world set_main_world edit_bases update_bases edit_trade_codes update_trade_codes replace do_replace toggle_lock assign_social_characteristics apply_social_characteristics link_modal quick_link ]
  before_action :set_form_context

  # GET /star_systems or /star_systems.json
  def index
    @star_systems = StarSystem.all
  end

  # GET /star_systems/1 or /star_systems/1.json or /star_systems/1.md
  def show
    @primary = @star_system.primary_star
    @orbiting_bodies = @star_system.orbiting_bodies

    respond_to do |format|
      format.html
      format.json
      format.md do
        presenter = StarSystemMarkdownPresenter.new(@star_system)
        render plain: presenter.render, content_type: 'text/markdown'
      end
    end
  end

  # GET /star_systems/1/map.svg or .webp
  def map
    @show_map_links = authenticated?
    fresh_when etag: "#{current_campaign.id}/#{@star_system.cache_key_with_version}/#{map_cache_variant}", last_modified: @star_system.updated_at
    return if performed?

    respond_to do |format|
      format.svg  { send_data cached_svg, type: 'image/svg+xml', disposition: 'inline' }
      format.html { send_data cached_svg, type: 'image/svg+xml', disposition: 'inline' }
      format.webp { send_data cached_webp, type: 'image/webp', disposition: 'inline' }
    end
  end

  def select_main_world
    @worlds = @star_system.stellar_objects.where.not(uwp: nil).order(:orbit_sequence)
  end

  def set_main_world
    @star_system.update(main_world_id: params[:main_world_id].presence)
    redirect_to @star_system, status: :see_other
  end

  def edit_bases
    @facilities = Facility.order(:code)
    @current_ids = @star_system.facility_ids.to_set
  end

  def update_bases
    @star_system.facility_ids = params[:facility_ids]&.reject(&:blank?)&.map(&:to_i) || []
    redirect_to @star_system, status: :see_other
  end

  def replace
  end

  def toggle_lock
    @star_system.update!(locked: !@star_system.locked?)
    redirect_to @star_system, status: :see_other
  end

  def do_replace
    if @star_system.locked?
      flash.now[:alert] = 'This star system is locked and cannot be replaced.'
      return render :replace, status: :unprocessable_entity
    end

    payload, error = generate_payload(new_star_system_params)

    if error
      flash.now[:alert] = error
      return render :replace, status: :unprocessable_entity
    end

    StarSystemImporter.new.reimport!(@star_system, payload)
    redirect_to @star_system, notice: 'Star system replaced.'
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :replace, status: :unprocessable_entity
  end

  def edit_trade_codes
    @trade_codes = TradeCode.order(:code)
    @current_ids = @star_system.trade_code_ids.to_set
  end

  def update_trade_codes
    @star_system.trade_code_ids = params[:trade_code_ids]&.reject(&:blank?)&.map(&:to_i) || []
    redirect_to @star_system, status: :see_other
  end

  def assign_social_characteristics
    @governments = Government.order(:code)
    @law_levels = LawLevel.order(:code)
  end

  def apply_social_characteristics
    assigner = SocialCharacteristicsAssigner.new(@star_system, generator_service)
    result = assigner.assign(social_characteristics_params)
    if result.success?
      redirect_to @star_system, notice: 'Social characteristics assigned.', status: :see_other
    else
      flash[:alert] = result.errors.to_sentence
      redirect_to @star_system, status: :see_other
    end
  end

  def link_modal
    setup_link_modal_ivars
    render layout: false
  end

  def quick_link
    network = CommunicationNetwork.find(params[:network_id])
    target  = StarSystem.find(params[:to_system_id])
    link    = NetworkLink.new(
      communication_network: network,
      from_star_system: @star_system,
      to_star_system: target
    )

    if link.save
      respond_to do |format|
        format.turbo_stream do
          setup_link_modal_ivars

          map_div_html = %(<div id="link-modal-map" class="mb-4 overflow-auto" data-controller="hex-stream"><div style="zoom: 0.75; line-height: 0;">#{@map_svg}</div></div>)
          streams = [
            turbo_stream.replace('link-modal-map',     html: map_div_html.html_safe),
            turbo_stream.replace('link-modal-systems', partial: 'star_systems/link_modal_systems'),
            turbo_stream.prepend("network-links-#{@star_system.id}",
                                 partial: 'star_systems/network_link_row',
                                 locals: { link: link, star_system_id: @star_system.id })
          ]

          parsec = @star_system.parsec
          subsector = parsec&.subsector
          if subsector
            embed_url = map_subsector_path(subsector, highlight: parsec.id, compact: true, t: Time.current.to_i)
            map_html = %(<object id="subsector-map" type="image/svg+xml" data="#{embed_url}" class="block h-full w-full" data-subsector-refresh-target="map">Subsector map</object>)
            streams << turbo_stream.replace('subsector-map', html: map_html.html_safe)
          end

          render turbo_stream: streams
        end
        format.html { redirect_to star_system_path(@star_system) }
      end
    else
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace('modal',
                                                    partial: 'shared/error_modal',
                                                    locals: { errors: link.errors.full_messages })
        end
        format.html { redirect_to star_system_path(@star_system) }
      end
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
    @travel_zones = TravelZone.ordered
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
    subsector = @star_system.parsec.subsector
    @star_system.destroy!

    respond_to do |format|
      format.html { redirect_to subsector_path(subsector), notice: 'Star system was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def map_cache_variant
    authenticated? ? 'auth' : 'public'
  end

  def cached_svg
    Rails.cache.fetch("system_map_svg/#{current_campaign.id}/#{@star_system.cache_key_with_version}/#{map_cache_variant}") do
      render_to_string(formats: [:svg], layout: false)
    end
  end

  def cached_webp
    Rails.cache.fetch("system_map_webp/#{current_campaign.id}/#{@star_system.cache_key_with_version}/#{map_cache_variant}") do
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
    }.merge(sophont_check_options).merge(max_tech_level_options).merge(native_tech_level_options).merge(realistic_star_distribution_options)
    result = generator_service.generate_star_system(build_config)

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

    config.reverse_merge!(sophont_check_options)
    config.reverse_merge!(max_tech_level_options)
    config.reverse_merge!(native_tech_level_options)
    config.reverse_merge!(realistic_star_distribution_options)
    result = generator_service.generate_star_system(config)

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
    }.merge(sophont_check_options).merge(max_tech_level_options).merge(native_tech_level_options).merge(realistic_star_distribution_options)
    result = generator_service.generate_star_system(build_config)

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

  def generate_payload(create_params)
    case create_params[:create_mode]
    when 'empty'
      spectral_type = create_params['primary_spectral_type']
      dwarf_type = %w[BD D].include?(spectral_type)
      if spectral_type.blank? || (!dwarf_type && (create_params['primary_spectral_subtype'].blank? || create_params['primary_luminosity'].blank?))
        return [nil, 'Spectral type, subtype, and luminosity class must all be provided']
      end
      primary = if dwarf_type
        { 'type' => spectral_type }
      else
        { 'type' => "#{spectral_type}#{create_params['primary_spectral_subtype']}", 'class' => create_params['primary_luminosity'] }
      end
      config = {
        'name'    => create_params['name'],
        'counts'  => { 'gasGiants' => 0, 'planetoidBelts' => 0, 'terrestrialPlanets' => 0 },
        'primary' => primary
      }.merge(sophont_check_options).merge(max_tech_level_options).merge(native_tech_level_options).merge(realistic_star_distribution_options)
      result = generator_service.generate_star_system(config)
      result.success? ? [result.value, nil] : [nil, result.errors.to_sentence]

    when 'random'
      result = generator_service.generate_star_system({ 'name' => create_params['name'] }.merge(sophont_check_options).merge(max_tech_level_options).merge(native_tech_level_options).merge(realistic_star_distribution_options))
      result.success? ? [result.value, nil] : [nil, result.errors.to_sentence]

    when 'build_configuration'
      validator = BuildConfigValidator.new(create_params['build_configuration'])
      unless validator.valid_for_star_system?
        @build_errors = validator.errors
        return [nil, 'Invalid build specification']
      end
      config = YAML.safe_load(
        create_params['build_configuration'],
        permitted_classes: [Date, Time],
        aliases: false
      ) || {}
      config.reverse_merge!(sophont_check_options)
      config.reverse_merge!(max_tech_level_options)
      config.reverse_merge!(native_tech_level_options)
      config.reverse_merge!(realistic_star_distribution_options)
      result = generator_service.generate_star_system(config)
      result.success? ? [result.value, nil] : [nil, result.errors.to_sentence]

    else
      [nil, 'Invalid create mode']
    end
  end

  def social_characteristics_params
    params.require(:social_characteristics).permit(
      :government_code,
      :law_level_code,
      :main_world_criteria,
      :allow_captive_government,
      population: [:min, :max],
      tech_level: [:min, :max]
    )
  end

  def star_system_edit_params
    params.expect(star_system: [:name, :notes, :allegiance_id, :travel_zone_id, :survey_index, :locked])
  end

  def sophont_check_options
    value = current_campaign.sophont_check.presence || (current_campaign.charted_space? ? 'none' : 'standard')
    { 'sophontCheck' => value }
  end

  def max_tech_level_options
    { 'maxTechLevel' => current_campaign.max_tech_level_value }
  end

  def native_tech_level_options
    { 'nativeTechLevel' => current_campaign.native_tech_level? }
  end

  def realistic_star_distribution_options
    { 'realisticStarDistribution' => current_campaign.realistic_star_distribution? }
  end

  def new_star_system_params
    params.expect(star_system: [:name, :parsec_id, :create_mode, :build_configuration, :primary_spectral_type, :primary_spectral_subtype, :primary_luminosity])
  end

  def star_system_params
    params.expect(star_system: [:name, :parsec_id, :notes, :survey_index])
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
    if %w[edit update].include?(action_name)
      @submit_label = 'Update core'
      @form_url = star_system_path(@star_system)
    elsif %w[replace do_replace].include?(action_name)
      @submit_label = 'Replace star system'
      @form_url = do_replace_star_system_path(@star_system)
    else
      @submit_label = 'Add star system'
      @form_url =
        if request.path.include?('/parsecs/')
          parsec_star_systems_path(@parsec)
        else
          polymorphic_path([@subsector || @sector, :star_systems])
        end
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
