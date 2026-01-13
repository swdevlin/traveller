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
  end

  # GET /star_systems/new
  def new
    @star_system = StarSystem.new

    @luminosity ||= 'V'

    @spectral_type = ''
    @spectral_subtype = ''

    @star_system.parsec_id = @parsec.id if @parsec

    @return_to = request.referer
  end

  # GET /star_systems/1/edit
  def edit
  end

  # POST /star_systems or /star_systems.json
  def create
    @star_system = generate_star_system

    if @star_system.errors.any?
      flash.now[:alert] = @star_system.errors.full_messages.to_sentence

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

  def generate_star_system
    unless params[:parsec_id].present?
      unless params.dig(:star_system, :parsec_id).present?
        return StarSystem.new(star_system_params).tap do |so|
          so.errors.add(:base, 'You must select a hex')
        end
      end
    end

    error = star_generate_params_errors
    unless error.nil?
      return StarSystem.new(star_system_params).tap do |so|
        so.errors.add(:base, error)
      end
    end

    sgp = star_generator_params
    definition = { name: star_system_params[:name] }

    unless @random
      definition[:primary] = {
        type: "#{sgp[:spectral_type]}#{sgp[:spectral_subtype]}",
        class: sgp[:luminosity]
      }
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
    @star_system = importer.import!(@parsec, data)
  end

  def star_system_edit_params
    params.expect(star_system: [:name, :notes])
  end

  def star_system_params
    params.expect(star_system: [:name, :parsec_id, :notes])
  end

  def star_generator_params
    params.expect(star_system: [:random_star, :luminosity, :spectral_type, :spectral_subtype])
  end

  def star_generate_params_errors
    sp = star_generator_params
    @random = ActiveModel::Type::Boolean.new.cast(sp[:random_star])
    return nil if @random
    missing = %i[luminosity spectral_type spectral_subtype].select { |k| sp[k].blank? }
    unless missing.empty?
      return "#{missing.join(', ')} must be provided"
    end
    if %w[O M].include?(sp['spectral_type']) && sp['luminosity'] == 'IV'
      return "#{sp['spectral_type']} IV stars are not supported by the generator."
    end
    if %w[A F].include?(sp['spectral_type']) && sp['luminosity'] == 'VI'
      return "#{sp['spectral_type']} VI stars are not supported by the generator."
    end
    if sp['spectral_type'] == 'K' && sp['spectral_subtype'] >= 5 && sp['luminosity'] == 'VI'
      return "#{sp['spectral_type']} VI stars are not supported by the generator."
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
