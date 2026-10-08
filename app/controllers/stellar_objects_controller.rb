class StellarObjectsController < ApplicationController
  include RecalculatesOrbitMechanics

  ALLOWED_STI_CLASSES = (StellarObject::STI_TYPES - ['Star']).to_h { |name| [name, name.constantize] }.freeze

  include UrlTokenVerification
  optional_authentication only: :map
  skip_before_action :verify_url_token, except: :map
  before_action :set_stellar_object, except: %i[index new create]

  # GET /stellar_objects or /stellar_objects.json
  def index
    @stellar_objects = StellarObject.all
  end

  # GET /stellar_objects/1 or /stellar_objects/1.json or /stellar_objects/1.md
  def show
    @starmap_center = if @stellar_object.parsec
      [@stellar_object.parsec.x, @stellar_object.parsec.y]
    else
      parsec = @stellar_object.orbiting.star_system.parsec
      [parsec.x, parsec.y]
    end
    @route_from_system = @stellar_object.parsec ? nil : @stellar_object.orbiting&.star_system

    if @stellar_object.is_a?(PlanetoidBelt)
      @planetoid_count = @stellar_object.significant_bodies.count
      scope = @stellar_object.listed_planetoids(significant_only: params[:significant_only].present?)
      @pagy, @planetoids = pagy(scope, limit: 10, params: request.query_parameters)
    elsif @stellar_object.is_a?(TerrestrialPlanet) || @stellar_object.is_a?(GasGiant)
      @moon_count = @stellar_object.moons.count
      scope = @stellar_object.moons.order(:orbit)
      scope = scope.where.not(size_code: %w[0 S]) if params[:significant_only].present?
      @pagy, @moons = pagy(scope, limit: 10, params: request.query_parameters)
    end

    respond_to do |format|
      format.html
      format.json
      format.md do
        presenter = StellarObjectMarkdownPresenter.for(@stellar_object)
        render plain: presenter.render, content_type: 'text/markdown'
      end
    end
  end

  # GET /stellar_objects/new
  def new
    @stellar_object = StellarObject.new
  end

  # GET /stellar_objects/1/edit
  def edit
  end

  # POST /stellar_objects or /stellar_objects.json
  def create
    @stellar_object = sti_class.new(stellar_object_params)

    respond_to do |format|
      if @stellar_object.save
        format.html { redirect_to stellar_object_url(@stellar_object), notice: "#{@stellar_object.type.underscore.humanize} was successfully created." }
        format.json { render :show, status: :created, location: @stellar_object }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @stellar_object.errors, status: :unprocessable_entity }
      end
    end
  end


  # PATCH/PUT /stellar_objects/1 or /stellar_objects/1.json
  def update
    respond_to do |format|
      if @stellar_object.update(stellar_object_params)
        recalculate_orbit_mechanics_if_needed(@stellar_object)
        format.html { redirect_to stellar_object_url(@stellar_object), notice: "#{@stellar_object.type.underscore.humanize} was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @stellar_object }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stellar_object.errors, status: :unprocessable_entity }
      end
    end
  end

  # GET /stellar_objects/1/daily_traffic
  def daily_traffic
    @frontier = false
    @traffic = DailyTrafficCalculator.new(
      importance: @stellar_object.importance,
      wtn:        @stellar_object.world_trade_number,
      frontier:   @frontier
    ).calculate
  end

  # POST /stellar_objects/1/generate_daily_traffic
  def generate_daily_traffic
    @frontier = params[:frontier] == '1'
    @traffic = DailyTrafficCalculator.new(
      importance: @stellar_object.importance,
      wtn:        @stellar_object.world_trade_number,
      frontier:   @frontier
    ).calculate
    render :daily_traffic
  end

  # POST /stellar_objects/1/regenerate_characteristics
  def regenerate_characteristics
    unless @stellar_object.is_a?(TerrestrialPlanet) || @stellar_object.is_a?(PlanetoidBelt)
      return redirect_to stellar_object_path(@stellar_object), alert: 'Characteristics can only be regenerated for terrestrial planets and planetoid belts.'
    end

    star = @stellar_object.orbiting
    unless star.is_a?(Star)
      return redirect_to stellar_object_path(@stellar_object), alert: 'Cannot regenerate characteristics for a rogue object without an orbiting star.'
    end

    result = generator_service.generate_from_uwp(
      uwp: @stellar_object.uwp,
      orbit: @stellar_object.orbit,
      star: { hzco: star.hzco, age: star.age, mass: star.mass, spread: star.spread }
    )

    unless result.success?
      return redirect_to stellar_object_path(@stellar_object), alert: result.errors.to_sentence
    end

    data = result.value

    ActiveRecord::Base.transaction do
      @stellar_object.assign_data_from_generator(data)
      @stellar_object.stellar_object_trade_codes.delete_all
      StellarObjectTradeCode.assign_from_codes!(@stellar_object, data['tradeCodes'])
      if @stellar_object.is_a?(TerrestrialPlanet) && data['moons'].present?
        @stellar_object.moons.destroy_all
        @stellar_object.assign_moons(data['moons'])
      end
      if @stellar_object.is_a?(PlanetoidBelt) && data['significantBodies'].present?
        @stellar_object.significant_bodies.destroy_all
        data['significantBodies'].each do |planetoid_data|
          planetoid = Planetoid.new
          planetoid.skip_import_callbacks = true
          planetoid.orbiting = @stellar_object.orbiting
          planetoid.assign_data_from_generator(planetoid_data)
          planetoid.planetoid_belt_id = @stellar_object.id
          planetoid.save!
        end
      end
      @stellar_object.save!
    end

    redirect_to stellar_object_path(@stellar_object), notice: 'Characteristics regenerated successfully.'
  rescue StandardError => e
    Rails.logger.error "regenerate_characteristics failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    redirect_to stellar_object_path(@stellar_object), alert: 'Could not regenerate characteristics at this time.'
  end

  # GET /stellar_objects/1/map
  def map
    planet_map = @stellar_object.try(:planet_map)
    return head :not_found unless planet_map&.webp&.attached?

    send_data planet_map.webp_data, type: 'image/webp', disposition: 'inline', filename: @stellar_object.map_download_filename
  end

  # POST /stellar_objects/1/generate_map
  def generate_map
    unless @stellar_object.try(:map_supported?)
      return redirect_to stellar_object_path(@stellar_object), alert: 'Maps can only be generated for terrestrial planets, planetoids and moons of size 1 or greater.'
    end

    rendered = map_service.render(map_payload, seed: MapService::PLANET_SEED)
    @stellar_object.store_map(rendered.svg)

    respond_to do |format|
      format.turbo_stream
    end
  rescue MapService::Error => e
    Rails.logger.error "generate_map failed: #{e.message}"
    @map_error = e.api_message
    respond_to do |format|
      format.turbo_stream
    end
  rescue StandardError => e
    Rails.logger.error "generate_map failed: #{e.class} - #{e.message}\n#{e.backtrace.first(5).join("\n")}"
    @map_error = 'Could not generate the map at this time.'
    respond_to do |format|
      format.turbo_stream
    end
  end

  # DELETE /stellar_objects/1 or /stellar_objects/1.json
  def destroy
    type = @stellar_object.type.underscore.humanize

    @stellar_object.destroy!

    respond_to do |format|
      format.html { redirect_to request.referer, notice: "#{type} deleted.", status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # The standard stellar object JSON, as served by the API.
    def map_payload
      json = render_to_string(partial: 'stellar_objects/stellar_object', formats: [:json],
                              locals: { stellar_object: @stellar_object })
      JSON.parse(json)
    end

    def sti_class
      t = params.dig(:stellar_object, :type)
      ALLOWED_STI_CLASSES.fetch(t) { raise ActionController::BadRequest, 'Invalid type' }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_stellar_object
      @stellar_object = StellarObject.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def stellar_object_params
      permitted = params.require(:stellar_object).permit(*@stellar_object.class.permitted_params)
      if permitted[:data].present?
        permitted[:data] = (@stellar_object.data || {}).merge(permitted[:data].to_h)
      end
      permitted
    end
end
