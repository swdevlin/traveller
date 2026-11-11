# frozen_string_literal: true

class CampaignSettingsController < ApplicationController
  def show
    @campaign = current_campaign
    @sector_count = Sector.count
    @subsector_count = Subsector.where.not(build: nil).count
    @extinct_sophont_count = StellarObject.where("data->>'extinct_sophont' = 'true'").count
    @native_sophont_count = StellarObject.where("data->>'native_sophont' = 'true'").count
    @star_system_count = StarSystem.count
  end

  def edit
    @campaign = current_campaign
  end

  def update
    @campaign = current_campaign
    if @campaign.update(campaign_settings_params)
      GenerateAllSectorsMapJob.perform_later(@campaign.id) if @campaign.saved_change_to_settings?
      redirect_to campaign_settings_path, notice: 'Campaign updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def populate_deepnight
    return head :unprocessable_entity unless current_campaign.deepnight_revelation?

    Apartment::Tenant.switch(current_campaign.schema_name) do
      PopulateDeepnightCampaignJob.perform_later(current_campaign.id, remaining: true)
    end
    redirect_to(params[:registry].present? ? sectors_path : campaign_settings_path, notice: 'Deepnight sector population queued.')
  end

  def assign_builds
    AssignBuildConfigsJob.perform_later(current_campaign.sector_source)
    redirect_to campaign_settings_path, notice: 'Build script assignment queued.'
  end

  def generate_all_sectors_map
    GenerateAllSectorsMapJob.perform_later(current_campaign.id)
    redirect_to campaign_settings_path, notice: 'All-sectors map generation queued.'
  end

  def regenerate_api_token
    current_campaign.update_column(:api_token, SecureRandom.hex(32))
    redirect_to campaign_settings_path, notice: 'API token regenerated. Update your Foundry module settings.'
  end

  private

  def campaign_settings_params
    params.expect(campaign: [:name, :campaign_type, :sector_source, :exploration, :sophont_check, :max_tech_level, :native_tech_level, :allow_captive_government, :orbit_distance_display, :realisticStarDistribution, :limited_main_world_eccentricity, :default_language, :date_format, :handout_paper_size,
                              :sector_capital_colour, :subsector_capital_colour, :hex_size,
                              :jump_log_display, :jump_log_fill_colour, :jump_log_line_colour,
                              :jump_log_line_style, :jump_log_line_width,
                              :starting_sector_x, :starting_sector_y])
  end
end
