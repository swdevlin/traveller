# frozen_string_literal: true

class StarsController < ApplicationController
  before_action :set_star, only: %i[ show edit update destroy ]
  rescue_from ActiveRecord::RecordNotFound, with: :star_not_found

  def lookup
    result = GeneratorService.new.lookup_star(
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
  end

  def edit
    set_form_options
  end

  def update
    if @star.update(star_params)
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

  def star_not_found
    redirect_to root_path, alert: 'That star no longer exists.'
  end

  def star_params
    params.require(:star).permit(
      :name, :stellar_type, :stellar_subtype, :stellar_class,
      :mass, :diameter, :temperature, :luminosity, :age,
      :minimum_orbit, :hzco, :colour, :orbit, :eccentricity
    )
  end

  def set_form_options
    @spectral_type_options = %w[O B A F G K M].map { |t| [t, t] }
    @spectral_type_options << ['Brown Dwarf', 'BD']
    @spectral_type_options << ['White Dwarf', 'D']

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
