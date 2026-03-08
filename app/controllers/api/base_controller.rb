class Api::BaseController < ActionController::API
  private

  def parsecs_in_region
    if params[:sx].present? && params[:sy].present?
      sx = params[:sx].to_i
      sy = params[:sy].to_i
      Parsec.where(x: (sx * 32)..(sx * 32 + 31), y: (sy * 40 - 39)..(sy * 40))
    elsif params[:ulx].present? && params[:uly].present? && params[:lrx].present? && params[:lry].present?
      Parsec.where(
        x: params[:ulx].to_i..params[:lrx].to_i,
        y: params[:lry].to_i..params[:uly].to_i
      )
    end
  end

  def star_systems_in_region
    parsecs = parsecs_in_region
    return nil if parsecs.nil?

    StarSystem.where(parsec: parsecs)
              .includes({ parsec: :sector }, :allegiance, :main_world, :trade_codes, :facilities, stars: :stellar_objects)
  end
end
