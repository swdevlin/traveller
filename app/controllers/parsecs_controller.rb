class ParsecsController < ApplicationController
  before_action :set_parsec, only: %i[ show edit update destroy ]

  # GET /parsecs or /parsecs.json
  def index
    @parsecs = Parsec.all
  end

  # GET /parsecs/1 or /parsecs/1.json
  def show
  end

  # GET /parsecs/new
  def new
    @parsec = Parsec.new
  end

  # GET /parsecs/1/edit
  def edit
  end

  # POST /parsecs or /parsecs.json
  def create
    @parsec = Parsec.new(parsec_params)

    respond_to do |format|
      if @parsec.save
        format.html { redirect_to @parsec, notice: 'Parsec was successfully created.' }
        format.json { render :show, status: :created, location: @parsec }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @parsec.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /parsecs/1 or /parsecs/1.json
  def update
    respond_to do |format|
      if @parsec.update(parsec_params)
        format.html { redirect_to @parsec, notice: 'Parsec was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @parsec }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @parsec.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /parsecs/1 or /parsecs/1.json
  def destroy
    @parsec.destroy!

    respond_to do |format|
      format.html { redirect_to parsecs_path, notice: 'Parsec was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_parsec
      @parsec = Parsec.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def parsec_params
      params.expect(parsec: [:sector_id, :x, :y])
    end
end
