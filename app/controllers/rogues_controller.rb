require "net/http"
require "uri"
require "json"

class RoguesController < ApplicationController
  before_action :load_parent!
  before_action :load_parsecs!
  before_action :set_context_label!

  def new
    @rogue = StellarObject.new

    # If we came from /parsecs/:parsec_id/rogues/new, preselect and hide selector
    @rogue.parsec_id = @parsec.id if @parsec

    @return_to = request.referer
  end

  def create
    @return_to = params[:return_to]
    @rogue = if params.dig(:stellar_object, :type) == 'GasGiant'
               fetch_gas_giant
             else
               StellarObject.new(rogue_params)
             end

    if @rogue.errors.any?
      flash.now[:alert] = @rogue.errors.full_messages.to_sentence
      return render :new, status: :unprocessable_entity
    end

    @rogue.star_system_id = nil

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
      redirect_to safe_return_to || after_create_path, notice: "Rogue #{@rogue.type.underscore.humanize(capitalize: false)} added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  # DELETE /stellar_objects/1 or /stellar_objects/1.json
  def destroy
    type = @stellar_object.type.underscore.humanize
    parsec = @stellar_object.parsec
    
    # Try to find a subsector if it's a rogue object (no star system)
    subsector = nil
    if @stellar_object.star_system_id.nil? && parsec
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

  def fetch_gas_giant
    size = params.dig(:stellar_object, :data, :size)
    if size.blank?
      return GasGiant.new(rogue_params).tap do |gg|
        gg.errors.add(:size, 'must be specified')
      end
    end
    if size == 'random'
      roller = DiceRoller.new
      size = table.roll(dm: 0, roller: roller)
    end

    uri = URI(Rails.application.config.x.generator_service)
    uri = uri + '/gasgiant'
    uri.query = URI.encode_www_form(size: size)

    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = 5
    http.read_timeout = 5

    # response = Net::HTTP.get_response(uri)
    response = http.get(uri.request_uri)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error "GasGiant API Failure: HTTP #{response.code} - #{response.body}"
      return GasGiant.new(rogue_params).tap do |gg|
        gg.errors.add(:base, 'Cannot create gas giant at this time')
      end
    end

    data =
      begin
        JSON.parse(response.body)
      rescue JSON::ParserError => e
        Rails.logger.error "GasGiant API JSON Error: #{e.message} - Body: #{response.body}"
        return GasGiant.new(rogue_params).tap do |gg|
          gg.errors.add(:base, 'Cannot create gas giant at this time')
        end
      end

    GasGiant.new(rogue_params.merge({
      diameter: data['diameter'],
      mass: data['mass'],
      data: {code: data['code']}
      })
    )
  rescue StandardError => e
    Rails.logger.error "GasGiant unexpected error: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    GasGiant.new(rogue_params).tap do |gg|
      gg.errors.add(:base, 'Cannot create gas giant at this time')
    end
  end

  def load_parent!
    @parsec = Parsec.find(params[:parsec_id]) if params[:parsec_id].present?
    @subsector = Subsector.find(params[:subsector_id]) if params[:subsector_id].present?
    @sector = Sector.find(params[:sector_id]) if params[:sector_id].present?

    @sector ||= @parsec&.sector
    @sector ||= @subsector&.sector
  end

  def load_parsecs!
    scope =
      if @parsec
        [@parsec]
      elsif @subsector
        @subsector.parsecs.includes(:sector)
      else
        @sector.parsecs.includes(:sector)
      end

    @parsecs = scope.sort_by(&:hex_code)

    label_method = @subsector ? :subsector_hex_code : :hex_code
    @parsec_options = @parsecs.map { |p| [p.public_send(label_method), p.id] }
  end

  def set_context_label!
    @context_label =
      if @parsec
        "#{@parsec.sector.name} #{@parsec.hex_code}"
      elsif @subsector
        "#{@subsector.name}, #{@subsector.sector.name}"
      else
        @sector.name
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
