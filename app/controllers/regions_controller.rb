require 'csv'

class RegionsController < ApplicationController
  before_action :set_region, only: %i[show edit update destroy import_hexes upload_hexes download_csv]

  def index
    @pagy, @regions = pagy(Region.includes(:sectors).order(:name), limit: 20)
  end

  def show
    rank = Region.order(:name).where('name < ?', @region.name).count
    @regions_list_page = (rank / 20) + 1
  end

  def new
    @region = Region.new
  end

  def edit
    @label_parsec_options = label_parsec_options_for(@region)
  end

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

  def download_csv
    border = @region.border_parsecs_ordered.includes(:parsec)

    csv = CSV.generate(headers: true) do |csv|
      csv << %w[sector_x sector_y hex_x hex_y]
      if border.any?
        border.each do |rp|
          p = rp.parsec
          sector = p.sector
          hex_x = p.x - sector.x * 32 + 1
          hex_y = sector.y * 40 - p.y + 1
          csv << [sector.x, sector.y, hex_x, hex_y]
        end
      else
        csv << [0, 0, 1, 1]
      end
    end

    send_data csv,
              filename: "#{@region.name.parameterize}-border.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def upload_hexes
    file = params[:csv_file]

    unless file.present? && file.original_filename.end_with?('.csv')
      return redirect_to @region, alert: 'Please upload a CSV file.'
    end

    result = RegionCsvImporter.new(@region, file.read).call

    if result[:ok]
      redirect_to @region, notice: 'Region hexes updated successfully.'
    else
      redirect_to @region, alert: result[:error]
    end
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @region, alert: "Import failed: #{e.message}"
  end

  def destroy
    @region.destroy!

    respond_to do |format|
      format.html { redirect_to regions_path, notice: 'Region was successfully destroyed.', status: :see_other }
      format.json { head :no_content }
    end
  end

  private

  def set_region
    @region = Region.includes(:sectors).find(params.expect(:id))
  end

  def region_params
    params.expect(region: [:name, :label, :label_colour, :colour, :border_colour, :notes, :player_visible])
  end

  def label_position_coords
    parsec_id = params.dig(:region, :label_parsec_id).presence
    return {} unless parsec_id

    parsec = Parsec.find_by(id: parsec_id)
    return {} unless parsec

    { label_x: parsec.x, label_y: parsec.y }
  end

  def label_parsec_options_for(region)
    region_parsecs = region.parsecs.includes(:sector).sort_by(&:hex_code)
    return [] if region_parsecs.empty?

    sectors = region_parsecs.map(&:sector).uniq

    if sectors.one?
      region_parsecs.map { |p| [p.hex_code, p.id] }
    else
      region_parsecs.group_by(&:sector).sort_by { |s, _| s.name }.map do |sector, parsecs|
        [sector.name, parsecs.map { |p| [p.hex_code, p.id] }]
      end
    end
  end
end
