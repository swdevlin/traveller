class AllegiancesController < ApplicationController
  before_action :set_allegiance, only: %i[ show edit update destroy ]

  # GET /allegiances or /allegiances.json
  def index
    @allegiances = Allegiance.order(:code)
  end

  # GET /allegiances/1 or /allegiances/1.json
  def show
  end

  # GET /allegiances/new
  def new
    @allegiance = Allegiance.new
    @return_to = request.referer
  end

  # GET /allegiances/1/edit
  def edit
  end

  # POST /allegiances or /allegiances.json
  def create
    @allegiance = Allegiance.new(allegiance_params)

    respond_to do |format|
      if @allegiance.save
        format.html { redirect_to params[:return_to].presence || @allegiance, notice: 'Allegiance was successfully created.' }
        format.json { render :show, status: :created, location: @allegiance }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @allegiance.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /allegiances/1 or /allegiances/1.json
  def update
    respond_to do |format|
      if @allegiance.update(allegiance_params)
        format.html { redirect_to @allegiance, notice: 'Allegiance was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @allegiance }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @allegiance.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /allegiances/1 or /allegiances/1.json
  def destroy
    @allegiance.destroy!

    respond_to do |format|
      format.html { redirect_to allegiances_path, notice: 'Allegiance was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_allegiance
      @allegiance = Allegiance.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def allegiance_params
      params.expect(allegiance: [:code, :name, :legacy_code])
    end
end
