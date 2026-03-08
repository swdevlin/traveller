require 'csv'

class RegionsController < ApplicationController
  before_action :set_region, only: %i[ show edit update destroy import_hexes upload_hexes hex_template ]

  # GET /regions or /regions.json
  def index
    @pagy, @regions = pagy(Region.includes(:sectors).order(:name), limit: 20)
  end

  # GET /regions/1 or /regions/1.json
  def show
    rank = Region.order(:name).where('name < ?', @region.name).count
    @regions_list_page = (rank / 20) + 1
  end

  # GET /regions/new
  def new
    @region = Region.new
  end

  # GET /regions/1/edit
  def edit
    @label_parsec_options = label_parsec_options_for(@region)
  end

  # POST /regions or /regions.json
  def create
    @region = Region.new(region_params)
    @region.source = 'manual'

    respond_to do |format|
      if @region.save
        format.html { redirect_to @region, notice: 'Region was successfully created.' }
        format.json { render :show, status: :created, location: @region }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @region.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /regions/1 or /regions/1.json
  def update
    respond_to do |format|
      if @region.update(region_params.merge(label_position_coords))
        format.html { redirect_to @region, notice: 'Region was successfully updated.', status: :see_other }
        format.json { render :show, status: :ok, location: @region }
      else
        @label_parsec_options = label_parsec_options_for(@region)
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @region.errors, status: :unprocessable_entity }
      end
    end
  end

  def import_hexes
  end

  def hex_template
    csv = CSV.generate(headers: true) do |csv|
      csv << %w[sector_x sector_y hex_x hex_y]
      csv << [0, 0, 1, 1]
    end

    send_data csv,
              filename: "#{@region.name.parameterize}-hexes-template.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def upload_hexes
    file = params[:csv_file]

    unless file.present? && file.original_filename.end_with?('.csv')
      return redirect_to @region, alert: 'Please upload a CSV file.'
    end

    rows = CSV.parse(file.read, headers: true, header_converters: :symbol).map do |row|
      { sector_x: row[:sector_x].to_i, sector_y: row[:sector_y].to_i,
        hex_x:    row[:hex_x].to_i,    hex_y:    row[:hex_y].to_i }
    end

    ImportRegionHexesJob.perform_later(@region.id, rows)
    redirect_to @region, notice: "Importing #{rows.size} #{'hex'.pluralize(rows.size)} in the background."
  end

  # DELETE /regions/1 or /regions/1.json
  def destroy
    @region.destroy!

    respond_to do |format|
      format.html { redirect_to regions_path, notice: 'Region was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_region
      @region = Region.includes(:sectors).find(params.expect(:id))
    end

    # Only allow a list of trusted parameters through.
    def region_params
      params.expect(region: [:name, :label, :label_colour, :colour, :border_colour, :notes])
    end

    def label_position_coords
      parsec_id = params.dig(:region, :label_parsec_id).presence
      return {} unless parsec_id

      parsec = Parsec.find_by(id: parsec_id)
      return {} unless parsec

      { label_x: parsec.x, label_y: parsec.y }
    end

    def label_parsec_options_for(region)
      sectors = region.sectors.includes(:parsecs)
      return [] if sectors.empty?

      if sectors.one?
        sectors.first.parsecs.sort_by(&:hex_code).map { |p| [p.hex_code, p.id] }
      else
        sectors.sort_by(&:name).map do |sector|
          [sector.name, sector.parsecs.sort_by(&:hex_code).map { |p| [p.hex_code, p.id] }]
        end
      end
    end
end
