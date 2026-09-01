class Api::StellarObjectsController < Api::BaseController
  include Pagy::Method

  helper ApplicationHelper, StellarObjectsHelper

  def show
    @stellar_object = StellarObject
                      .includes(:moons, :orbiting, :parsec, :allegiance)
                      .find_by(id: params[:id])
    render json: { error: 'stellar object not found' }, status: :not_found unless @stellar_object
  end

  def moons
    stellar_object = StellarObject.find_by(id: params[:id])
    return render json: { error: 'stellar object not found' }, status: :not_found unless stellar_object

    authenticated_by_session?
    is_referee = Current.owns_campaign?
    star_system = stellar_object.star_system
    player_visible = is_referee || (star_system.present? && (star_system.known? || star_system.survey_index >= 10))
    return render json: { error: 'stellar object not found' }, status: :not_found unless player_visible

    scope = stellar_object.moons.order(:orbit)
    scope = scope.where.not(size_code: %w[0 S]) if params[:significant_only].present?
    @pagy, @moons = pagy(scope, limit: 10, params: request.query_parameters)
  end

  def cities
    stellar_object = StellarObject.find_by(id: params[:id])
    return render json: { error: 'stellar object not found' }, status: :not_found unless stellar_object

    authenticated_by_session?
    is_referee = Current.owns_campaign?
    star_system = stellar_object.star_system
    player_visible = is_referee || (star_system.present? && (star_system.known? || star_system.survey_index >= 10))
    return render json: { error: 'stellar object not found' }, status: :not_found unless player_visible
    return render json: { error: 'stellar object not found' }, status: :not_found unless stellar_object.respond_to?(:cities)

    scope = stellar_object.cities.order(population: :desc)
    @pagy, @cities = pagy(scope, limit: 10, params: request.query_parameters)
  end
end
