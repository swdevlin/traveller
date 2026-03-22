# frozen_string_literal: true

class CampaignSettingsController < ApplicationController
  def show
    @campaign = current_campaign
    @sector_count = Sector.count
    @subsector_count = Subsector.where.not(build: nil).count
    populated_sector_ids = Sector.joins(parsecs: :star_systems).select(:id)
    empty_sector_ids = Sector.kept.where.not(id: populated_sector_ids).select(:id)
    @empty_sector_count = Sector.kept.where(id: empty_sector_ids).count
    @empty_subsector_count = Subsector.where(sector_id: empty_sector_ids).where.not(build: nil).count
    @extinct_sophont_count = StellarObject.where("data->>'extinct_sophont' = 'true'").count
    @native_sophont_count = StellarObject.where("data->>'native_sophont' = 'true'").count
    @star_system_count = StarSystem.count
    @has_empty_sectors = @empty_subsector_count > 0
  end

  def edit
    @campaign = current_campaign
  end

  def update
    @campaign = current_campaign
    if @campaign.update(campaign_settings_params)
      redirect_to campaign_settings_path, notice: 'Campaign updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def populate_deepnight
    Apartment::Tenant.switch(current_campaign.schema_name) do
      PopulateDeepnightCampaignJob.perform_later(current_campaign.id)
    end
    redirect_to campaign_settings_path, notice: 'Deepnight sector population queued.'
  end

  def assign_builds
    AssignBuildConfigsJob.perform_later(current_campaign.sector_source)
    redirect_to campaign_settings_path, notice: 'Build script assignment queued.'
  end

  def populate_all
    PopulateAllSectorsJob.perform_later
    redirect_to campaign_settings_path, notice: 'Sector population queued.'
  end

  def populate_empty
    PopulateEmptySectorsJob.perform_later
    redirect_to campaign_settings_path, notice: 'Empty sector population queued.'
  end

  def generate_all_sectors_map
    GenerateAllSectorsMapJob.perform_later(current_campaign.id)
    redirect_to campaign_settings_path, notice: 'All-sectors map generation queued.'
  end

  private

  def campaign_settings_params
    params.expect(campaign: [:name, :campaign_type, :sector_source, :tracks_survey_index, :sophont_check, :max_tech_level, :native_tech_level, :native_sophont_colour, :extinct_sophont_colour, :show_native_sophont, :show_extinct_sophont, :allow_captive_government])
  end
end
