class GovernmentsController < ApplicationController
  before_action :set_government, only: %i[ show edit update destroy ]

  # GET /governments or /governments.json
  def index
    @governments = Government.all
  end

  # GET /governments/1 or /governments/1.json
  def show
  end

  # GET /governments/new
  def new
    @government = Government.new
    @return_to = request.referer
  end

  # GET /governments/1/edit
  def edit
  end

  # POST /governments or /governments.json
  def create
    @government = Government.new(government_params)

    respond_to do |format|
      if @government.save
        format.html { redirect_to params[:return_to].presence || @government, notice: 'Government was successfully created.' }
        format.json { render :show, status: :created, location: @government }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @government.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /governments/1 or /governments/1.json
  def update
    respond_to do |format|
      if @government.update(government_params)
        format.html { redirect_to @government, notice: 'Government was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @government }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @government.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /governments/1 or /governments/1.json
  def destroy
    @government.destroy!

    respond_to do |format|
      format.html { redirect_to governments_path, notice: 'Government was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_government
      @government = Government.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def government_params
      params.expect(government: [:code, :type, :description])
    end
end
