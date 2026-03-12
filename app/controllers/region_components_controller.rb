require 'csv'

class RegionComponentsController < ApplicationController
  before_action :set_region
  before_action :set_component

  def destroy
    @component.destroy!
    redirect_to @region, notice: 'Component deleted.', status: :see_other
  end

  def hex_template
    csv = CSV.generate(headers: true) do |csv|
      csv << %w[sector_x sector_y hex_x hex_y]
      @component.fill_parsecs.includes(parsec: :sector).each do |rp|
        parsec = rp.parsec
        sector = parsec.sector
        ul = sector.upper_left
        csv << [sector.x, sector.y, parsec.x - ul.x + 1, ul.y - parsec.y + 1]
      end
    end

    send_data csv,
              filename: "#{@region.name.parameterize}-component-#{@component.id}-hexes.csv",
              type: 'text/csv',
              disposition: 'attachment'
  end

  def import_hexes
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

    ReplaceComponentHexesJob.perform_later(@component.id, rows)
    redirect_to @region, notice: "Replacing component hexes with #{rows.size} #{'hex'.pluralize(rows.size)} in the background."
  end

  private

  def set_region
    @region = Region.find(params[:region_id])
  end

  def set_component
    @component = @region.region_components.find(params[:id])
  end
end
