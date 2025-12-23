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
    @rogue = StellarObject.new(rogue_params)
    @rogue.solar_system_id = nil

    unless StellarObject::STI_TYPES.include?(@rogue.type)
      @rogue.errors.add(:type, 'is not a valid type')
      @return_to = params[:return_to]
      return render :new, status: :unprocessable_entity
    end

    # If we came from a parsec route, force it (ignore any posted parsec_id)
    @rogue.parsec_id = @parsec.id if @parsec

    # Safety: ensure parsec belongs to the allowed scope (sector/subsector)
    unless @parsecs.any? { |p| p.id == @rogue.parsec_id }
      @rogue.errors.add(:parsec_id, 'is not in scope')
      return render :new, status: :unprocessable_entity
    end

    if @rogue.save
      redirect_to safe_return_to || after_create_path, notice: "Rogue #{@rogue.type.underscore.humanize(capitalize: false)} added."
    else
      @return_to = params[:return_to]
      render :new, status: :unprocessable_entity
    end
  end

  private

  def load_parent!
    @parsec = Parsec.find(params[:parsec_id]) if params[:parsec_id]
    @subsector = Subsector.find(params[:subsector_id]) if params[:subsector_id]
    @sector = Sector.find(params[:sector_id]) if params[:sector_id]

    # convenience: if parsec/subsector implies a sector
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
    root_path
  end

  def safe_return_to
    return_to = params[:return_to].presence
    return unless return_to

    uri = URI.parse(return_to) rescue nil
    return unless uri

    # Only allow same-host redirects (prevents open redirect issues)
    return unless uri.host.nil? || uri.host == request.host

    uri.to_s
  end
end
