class JumpLogsController < ApplicationController
  before_action :set_jump_log, only: %i[ show edit update destroy ]

  # GET /jump_logs or /jump_logs.json
  def index
    scope = JumpLog.includes(:ship, from_parsec: :sector, to_parsec: :sector)
                   .order(sequence: :desc, id: :desc)
    @pagy, @jump_logs = pagy(scope, limit: 25)
  end

  # GET /jump_logs/1 or /jump_logs/1.json
  def show
    viewport = helpers.jump_chart_viewport(@jump_log.from_parsec, @jump_log.to_parsec)
    @map_url = api_map_path(viewport)
  end

  # GET /jump_logs/new
  def new
    last = JumpLog.includes(to_parsec: :sector).order(sequence: :desc, id: :desc).first
    @jump_log = JumpLog.new(
      from_parsec: last&.to_parsec,
      depart_year: last&.arrive_year,
      depart_day:  last&.arrive_day
    )
    @map_url = api_map_path(helpers.jump_chart_viewport(@jump_log.from_parsec)) if @jump_log.from_parsec
    load_form_collections
  end

  # GET /jump_logs/1/edit
  def edit
    @map_url = api_map_path(helpers.jump_chart_viewport(@jump_log.from_parsec)) if @jump_log.from_parsec
    load_form_collections
  end

  # POST /jump_logs or /jump_logs.json
  def create
    @jump_log = JumpLog.new(jump_log_params)

    respond_to do |format|
      if @jump_log.save
        format.html { redirect_to jump_logs_path, notice: 'Jump log was successfully created.' }
        format.json { render :show, status: :created, location: @jump_log }
      else
        load_form_collections
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @jump_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /jump_logs/1 or /jump_logs/1.json
  def update
    respond_to do |format|
      if @jump_log.update(jump_log_params)
        format.html { redirect_to @jump_log, notice: 'Jump log was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @jump_log }
      else
        load_form_collections
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @jump_log.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /jump_logs/1 or /jump_logs/1.json
  def destroy
    @jump_log.destroy!

    respond_to do |format|
      format.html { redirect_to jump_logs_path, notice: 'Jump log was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_jump_log
      @jump_log = JumpLog.includes(from_parsec: :sector, to_parsec: :sector).find(params.expect(:id))
    end

    def load_form_collections
      @ships = Ship.order(:name)
      @sectors = Sector.order(:name)
    end

    # Only allow a list of trusted parameters through.
    def jump_log_params
      params.expect(jump_log: [:ship_id, :from_parsec_id, :to_parsec_id, :depart_year, :depart_day, :arrive_year, :arrive_day, :notes, :misjump])
    end
end
