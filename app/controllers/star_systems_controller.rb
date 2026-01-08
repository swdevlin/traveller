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

    return_to = params[:return_to].presence

    if return_to && URI.parse(return_to).host.nil?
      redirect_to return_to, notice: 'Star system created.'
    else
      redirect_to fallback_return_path, notice: 'Star system created.'
    end
  end

  # PATCH/PUT /star_systems/1 or /star_systems/1.json
  def update
    respond_to do |format|
      if @star_system.update(star_system_params)
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

  def after_create_path
    return parsec_path(@parsec) if @parsec
    return subsector_path(@subsector) if @subsector
    return sector_path(@sector) if @sector
    sectors_path
  end

  # Use callbacks to share common setup or constraints between actions.
  def set_star_system
    @star_system = StarSystem.find(params.expect(:id))
  end

  def generate_star_system
    definition = { name: star_system_params[:name] }
    unless params.dig(:star_system, :random_star) == '1'
      # set up the primary
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

  def star_system_params
    params.expect(star_system: [:name, :parsec_id, :notes])
  end

  def star_generator_params
    params.expect(star_system: [:random_star, :luminosity, :spectral_type, :spectral_subtype])
  end

  def set_form_context
    @submit_label = action_name == 'edit' ? 'Save changes' : 'Add star system'

    @form_url =
      if request.path.include?('/parsecs/')
        parsec_star_systems_path(@parsec)
      else
        polymorphic_path([@subsector || @sector, :star_systems])
      end
  end

  def fallback_return_path
    if params[:subsector_id]
      subsector_path(params[:subsector_id])
    elsif params[:sector_id]
      sector_path(params[:sector_id])
    elsif params[:parsec_id]
      parsec_path(params[:parsec_id])
    else
      root_path
    end
  end
end
