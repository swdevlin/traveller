class FacilitiesController < ApplicationController
  before_action :set_facility, only: %i[ show edit update destroy ]

  # GET /facilities or /facilities.json
  def index
    @facilities = Facility.all.order(:code)
  end

  # GET /facilities/1 or /facilities/1.json
  def show
  end

  # GET /facilities/new
  def new
    @facility = Facility.new
    @return_to = request.referer
  end

  # GET /facilities/1/edit
  def edit
  end

  # POST /facilities or /facilities.json
  def create
    @facility = Facility.new(facility_params)

    respond_to do |format|
      if @facility.save
        format.html { redirect_to params[:return_to].presence || @facility, notice: 'Base was successfully created.' }
        format.json { render :show, status: :created, location: @facility }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @facility.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /facilities/1 or /facilities/1.json
  def update
    respond_to do |format|
      if @facility.update(facility_params)
        format.html { redirect_to @facility, notice: 'Base was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @facility }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @facility.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /facilities/1 or /facilities/1.json
  def destroy
    @facility.destroy!

    respond_to do |format|
      format.html { redirect_to facilities_path, notice: 'Base was deleted.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_facility
      @facility = Facility.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def facility_params
      params.expect(facility: [:name, :code, :traveller_map_code, :icon_class])
    end
end
