# frozen_string_literal: true

class SocialCharacteristicsPresetsController < ApplicationController
  def index
    presets = SocialCharacteristicsPreset.ordered
    render json: presets.map { |p| { id: p.id, name: p.name, settings: p.settings } }
  end

  def create
    preset = SocialCharacteristicsPreset.new(name: params[:name], settings: preset_settings)
    if preset.save
      render json: { id: preset.id, name: preset.name, settings: preset.settings }, status: :created
    else
      render json: { errors: preset.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def destroy
    SocialCharacteristicsPreset.find(params[:id]).destroy!
    head :no_content
  end

  private

  def preset_settings
    params.require(:settings).permit(
      :government_code,
      :law_level_code,
      :starport_code,
      :main_world_criteria,
      :allow_captive_government,
      :allegiance_id,
      population: [:min, :max],
      tech_level: [:min, :max]
    )
  end
end
