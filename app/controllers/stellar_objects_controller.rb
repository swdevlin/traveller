class StellarObjectsController < ApplicationController
  ALLOWED_STI_CLASSES = (StellarObject::STI_TYPES - ['Star']).to_h { |name| [name, name.constantize] }.freeze

  before_action :set_stellar_object, only: %i[ show edit update destroy ]

  # GET /stellar_objects or /stellar_objects.json
  def index
    @stellar_objects = StellarObject.all
  end

  # GET /stellar_objects/1 or /stellar_objects/1.json
  def show
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

    # Only allow a list of trusted parameters through.
    def stellar_object_params
      permitted = params.require(:stellar_object).permit(*@stellar_object.class.permitted_params)
      if permitted[:data].present?
        permitted[:data] = (@stellar_object.data || {}).merge(permitted[:data].to_h)
      end
      permitted
    end
end
