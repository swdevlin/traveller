# frozen_string_literal: true

class StarsController < ApplicationController
  include RecalculatesOrbitMechanics
  include UrlTokenVerification
  include SubwayMapRendering
  include OrbitMapRendering
  optional_authentication only: :map

  before_action :set_star, only: %i[ show edit update destroy map orbit_map orbit_map_modal ]
  rescue_from ActiveRecord::RecordNotFound, with: :star_not_found

  def lookup
    result = generator_service.lookup_star(
      stellar_type: params[:stellar_type],
      stellar_subtype: params[:stellar_subtype],
      stellar_class: params[:stellar_class]
    )

    if result.success?
      render json: result.value
    else
      render json: { error: result.errors.to_sentence }, status: :bad_request
    end
  end

  def show
    respond_to do |format|
      format.html
      format.md do
        presenter = StarMarkdownPresenter.new(@star)
        render plain: presenter.render, content_type: 'text/markdown'
      end
    end
  end

  # GET /stars/1/map.svg or .webp
  def map
    return head :not_found unless @star.star_system

    send_subway_map
  end

  # GET /stars/1/orbit_map_modal
  def orbit_map_modal
    @orbit_map = StarOrbitMap.new(@star, theme: current_theme_key, link_builder: method(:orbit_map_link))
    render layout: false
  end

  # GET /stars/1/orbit_map.webp
  def orbit_map
    respond_to do |format|
      format.webp { send_data cached_orbit_map_webp(@star, theme: current_theme_key), type: 'image/webp', disposition: 'inline' }
    end
  end

  def edit
    set_form_options
  end

  def update
    if @star.update(star_params)
      recalculate_orbit_mechanics_if_needed(@star)
      redirect_to star_path(@star), notice: 'Star was successfully updated.', status: :see_other
    else
      set_form_options
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    star_system = @star.star_system

    @star.destroy!

    redirect_to star_system_path(star_system), notice: 'Star was deleted.', status: :see_other
  end

  private

  def set_star
    @star = Star.find(params.expect(:id))
  end

  def current_theme_key = OrbitMapTheme.key_for(helpers.current_theme)

  def subway_map_cache_prefix = "star_map_#{@star.id}"

  # The star system is touched when any of its objects change, so its cache version
  # covers the star's children as well as the star itself.
  def subway_map_record = @star.star_system

  def subway_map_layout = StarSystemMapLayout.for_star(@star, moons: map_moons_mode)

  def star_not_found
    redirect_to root_path, alert: 'That star no longer exists.'
  end

  def star_params
    params.require(:star).permit(
      :name, :stellar_type, :stellar_subtype, :stellar_class,
      :mass, :diameter, :temperature, :luminosity, :age,
      :minimum_allowable_orbit, :hzco, :colour, :orbit, :eccentricity
    )
  end

  def set_form_options
    @spectral_type_options = %w[O B A F G K M].map { |t| [t, t] }
    @spectral_type_options << ['Brown Dwarf', 'BD']
    @spectral_type_options << ['White Dwarf', 'D']
    @spectral_type_options << ['L Dwarf', 'L']
    @spectral_type_options << ['T Dwarf', 'T']
    @spectral_type_options << ['Y Dwarf', 'Y']

    @spectral_subtype_options = (0..9).map { |n| [n.to_s, n] }

    @luminosity_options = [
      ['0 (Hypergiant)', '0'],
      ['Ia (Luminous supergiant)', 'Ia'],
      ['Iab (Intermediate supergiant)', 'Iab'],
      ['Ib (Less luminous supergiant)', 'Ib'],
      ['II (Bright giant)', 'II'],
      ['III (Giant)', 'III'],
      ['IV (Subgiant)', 'IV'],
      ['V (Main sequence)', 'V'],
      ['VI (Subdwarf)', 'VI'],
      ['VII (White dwarf)', 'VII']
    ]
  end
end
