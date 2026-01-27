class LawLevelsController < ApplicationController
  before_action :set_law_level, only: %i[ show edit update destroy ]

  # GET /law_levels or /law_levels.json
  def index
    @law_levels = LawLevel.all
  end

  # GET /law_levels/1 or /law_levels/1.json
  def show
  end

  # GET /law_levels/new
  def new
    @law_level = LawLevel.new
  end

  # GET /law_levels/1/edit
  def edit
  end

  # POST /law_levels or /law_levels.json
  def create
    @law_level = LawLevel.new(law_level_params)

    respond_to do |format|
      if @law_level.save
        format.html { redirect_to @law_level, notice: 'Law level was successfully created.' }
        format.json { render :show, status: :created, location: @law_level }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @law_level.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /law_levels/1 or /law_levels/1.json
  def update
    respond_to do |format|
      if @law_level.update(law_level_params)
        format.html { redirect_to @law_level, notice: 'Law level was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @law_level }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @law_level.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /law_levels/1 or /law_levels/1.json
  def destroy
    @law_level.destroy!

    respond_to do |format|
      format.html { redirect_to law_levels_path, notice: 'Law level was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_law_level
      @law_level = LawLevel.find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def law_level_params
      params.expect(law_level: [:code, :armour, :weapons, :economic_law, :criminal_law, :private_law, :personal_law, :notes])
    end
end
