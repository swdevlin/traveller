class StellarObjectsController < ApplicationController
  before_action :set_stellar_object, only: %i[ show edit update destroy ]

  # GET /stellar_objects or /stellar_objects.json
  def index
    @stellar_objects = StellarObject.all
  end

  # GET /stellar_objects/1 or /stellar_objects/1.json
  def show
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

      allowed = StellarObject::STI_TYPES - ['Star'] # Stars are created through the star system flow
      raise ActionController::BadRequest, 'Invalid type' unless allowed.include?(t)

      t.constantize
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
