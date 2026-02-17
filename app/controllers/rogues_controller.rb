require 'net/http'
require 'uri'
require 'json'

class RoguesController < ApplicationController
  include ParentHex

  def new
    @rogue = StellarObject.new

    # If we came from /parsecs/:parsec_id/rogues/new, preselect and hide selector
    @rogue.parsec_id = @parsec.id if @parsec

    @return_to = request.referer
  end

  def create
    @return_to = params[:return_to]

    @rogue = case params.dig(:stellar_object, :type)
    when 'GasGiant'
        generate_gas_giant
    when 'PlanetoidBelt'
        generate_stellar_object(PlanetoidBelt)
    when 'TerrestrialPlanet'
        TerrestrialPlanet.new(rogue_params)
    else
        StellarObject.new(rogue_params)
    end

    if @rogue.errors.any?
      flash.now[:alert] = @rogue.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    @rogue.orbiting_star_id = nil

    unless StellarObject::STI_TYPES.include?(@rogue.type)
      @rogue.errors.add(:type, 'is not a valid type')
      flash.now[:alert] = @rogue.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    # If we came from a parsec route, force it (ignore any posted parsec_id)
    @rogue.parsec_id = @parsec.id if @parsec

    # Safety: ensure parsec belongs to the allowed scope (sector/subsector)
    unless @parsecs.any? { |p| p.id == @rogue.parsec_id }
      @rogue.errors.add(:parsec_id, 'is not a valid parsec id')
      flash.now[:alert] = @rogue.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    if @rogue.save
      if @rogue.is_a?(TerrestrialPlanet)
        redirect_to edit_stellar_object_path(@rogue), notice: 'Rogue terrestrial planet created. Fill in the details.'
      else
        redirect_to after_create_path, notice: "Rogue #{@rogue.type.underscore.humanize(capitalize: false)} added."
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /stellar_objects/1 or /stellar_objects/1.json
  def destroy
    type = @stellar_object.type.underscore.humanize
    parsec = @stellar_object.parsec
    # Try to find a subsector if it's a rogue object (not orbiting a star)
    subsector = nil
    if @stellar_object.sorbiting_star_id.nil? && parsec
      subsector = Subsector.all.find { |s| s.parsecs.include?(parsec) }
    end

    @stellar_object.destroy!

    respond_to do |format|
      redirect_path = if subsector
        subsector_path(subsector)
      elsif parsec
        parsec_path(parsec)
      else
        stellar_objects_path
      end

      format.html { redirect_to redirect_path, notice: "#{type} was deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def generate_gas_giant
    size = params.dig(:stellar_object, :data, :size)
    if size.blank?
      return GasGiant.new(rogue_params).tap do |gg|
        gg.errors.add(:size, 'must be specified')
      end
    end

    if size == 'random'
      roller = DiceRoller.new
      table = GasGiantSizeTable.new
      size = table.roll(dm: 0, roller: roller)
    end

    generate_stellar_object(GasGiant, { size: size })
  end

  def generate_stellar_object(klass, params = {})
    base = Rails.application.config.x.generator_service
    uri  = URI.join(base.end_with?('/') ? base : "#{base}/", klass.name.underscore)
    uri.query = URI.encode_www_form(params) if params.present?

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5

    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "#{uri} Failure: HTTP #{response.code} - #{response.body}"
      return klass.new(rogue_params).tap do |so|
        so.errors.add(:base, "Cannot create #{klass.name.underscore.humanize(capitalize: false)} at this time")
      end
    end

    data =
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "#{uri} JSON Error: #{e.message} - Body: #{response.body}"
        return klass.new(rogue_params).tap do |so|
          so.errors.add(:base, "Cannot create #{klass.name.underscore.humanize(capitalize: false)} at this time")
        end
      end

    so = klass.new(rogue_params)
    so.assign_data_from_generator(data)
    so
  rescue StandardError => e
    Rails.logger.error "#{uri} unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    klass.new(rogue_params).tap do |so|
      so.errors.add(:base, "Cannot create #{klass.name.underscore.humanize(capitalize: false)} at this time")
    end
  end

  def rogue_params
    raw_type = params.dig(:stellar_object, :type).to_s
    klass = StellarObject.sti_class_for(raw_type)

    data_keys = klass ? klass.allowed_data_keys : []

    params.require(:stellar_object).permit(:parsec_id, :type, :name, :notes, data: data_keys)
  end

  def after_create_path
    return parsec_path(@parsec) if @parsec
    return subsector_path(@subsector) if @subsector
    return sector_path(@sector) if @sector
    sectors_path
  end

  def safe_return_to
    return_to = params[:return_to].presence
    return unless return_to

    uri = URI.parse(return_to) rescue nil
    return unless uri

    return unless uri.host.nil? || uri.host == request.host

    uri.to_s
  end
end
