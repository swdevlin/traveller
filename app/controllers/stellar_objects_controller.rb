class StellarObjectsController < ApplicationController
  ALLOWED_STI_CLASSES = (StellarObject::STI_TYPES - ['Star']).to_h { |name| [name, name.constantize] }.freeze

  before_action :set_stellar_object, only: %i[ show edit update destroy regenerate_characteristics ]

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
      scope = @stellar_object.significant_bodies
      @planetoid_count = scope.count
      if params[:significant_only].present?
        scope = scope.where.not(size_code: %w[0 S]).order(:orbit)
      else
        scope = scope.order(Arel.sql("array_position(ARRAY[#{StellarObject::SIZE_CODES.map { |c| "'#{c}'" }.join(',')}]::text[], size_code) DESC"))
                     .order(:orbit)
      end
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
        format.html { redirect_to stellar_object_url(@stellar_object), notice: "#{@stellar_object.type.underscore.humanize} was successfully updated.", status: :see_other }
        format.json { render :show, status: :ok, location: @stellar_object }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @stellar_object.errors, status: :unprocessable_entity }
      end
    end
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
      apply_stellar_object_trade_codes(@stellar_object, data['tradeCodes'])
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
    def sti_class
      t = params.dig(:stellar_object, :type)
      ALLOWED_STI_CLASSES.fetch(t) { raise ActionController::BadRequest, 'Invalid type' }
    end

    # Use callbacks to share common setup or constraints between actions.
    def set_stellar_object
      @stellar_object = StellarObject.find(params.expect(:id))
    end

    def apply_stellar_object_trade_codes(stellar_object, codes)
      return if codes.blank?

      codes.uniq.each do |code|
        trade_code = TradeCode.find_by(code: code)
        next unless trade_code

        StellarObjectTradeCode.find_or_create_by!(
          stellar_object: stellar_object,
          trade_code: trade_code
        )
      end
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
