require 'net/http'
require 'uri'
require 'json'
require 'yaml'

class StarSystemsController < ApplicationController
  include ParentHex
  before_action :set_star_system, only: %i[ show edit update destroy ]
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
      generate_star_system(random: true)
    when 'build_configuration'
      generate_build_configuration_star_system
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

  # Use callbacks to share common setup or constraints between actions.
  def set_star_system
    @star_system = StarSystem.find(params.expect(:id))
  end

  def create_empty_star_system(params)
    @parsec ||= Parsec.find(params[:parsec_id].to_i)

    # create the star system
    @star_system = StarSystem.new
    @star_system.parsec = @parsec
    @star_system.name = params['name']
    @star_system.save!

    # create the primary star
    primary = Star.new
    primary.star_system = @star_system
    primary.stellar_subtype = params['primary_spectral_subtype']
    primary.stellar_type = params['primary_spectral_type']
    primary.stellar_class = params['primary_luminosity']
    primary.save!

    @star_system
  rescue ActiveRecord::RecordInvalid => e
    e.record
  end

  def generate_build_configuration_star_system
    StarSystem.new.tap { |s| s.errors.add(:base, 'Build configuration mode is not yet implemented') }
  end

  def generate_star_system(random: true)
    unless star_system_params[:parsec_id].present?
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:parsec_id, 'You must select a hex')
      end
    end

    unless random
      error = star_generate_params_errors
      unless error.nil?
        return StarSystem.new(star_system_params).tap do |so|
          so.errors.add(:base, error)
        end
      end
    end

    sgp = star_generator_params
    definition = { name: star_system_params[:name] }

    unless random
      definition[:primary] = build_star_definition(sgp, 'primary')

      if sgp['primary_companion_enabled'] == '1'
        definition[:primary][:companion] = build_star_definition(sgp, 'primary_companion')
      end

      %w[close near far].each do |orbit|
        if sgp["#{orbit}_enabled"] == '1'
          definition[:primary][orbit.to_sym] = build_star_definition(sgp, orbit)

          if sgp["#{orbit}_companion_enabled"] == '1'
            definition[:primary][orbit.to_sym][:companion] = build_star_definition(sgp, "#{orbit}_companion")
          end
        end
      end
    end

    base = Rails.application.config.x.generator_service
    uri  = URI.join(base.end_with?('/') ? base : "#{base}/", 'star_system')

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 50
    http.read_timeout = 50
    headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }

    response = http.post(uri.request_uri, definition.to_json, headers)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, 'Cannot create star system at this time')
      end
    end

    data =
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}"
        return StarSystem.new(star_system_params).tap do |so|
          so.errors.add(:base, 'Cannot create star system at this time')
        end
      end

    importer = StarSystemImporter.new
    @parsec ||= Parsec.find(star_system_params[:parsec_id])
    importer.import!(@parsec, data)
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

  def set_form_context
    @submit_label = action_name == 'edit' ? 'Save changes' : 'Add star system'

    @form_url =
      if request.path.include?('/parsecs/')
        parsec_star_systems_path(@parsec)
      else
        polymorphic_path([@subsector || @sector, :star_systems])
      end
    @spectral_type_options = %w[O B A F G K M].map { |t| [t, t] }
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
