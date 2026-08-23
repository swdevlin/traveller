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

  def regenerate_all
    RegenerateAllSectorsJob.perform_later
    redirect_to campaign_settings_path, notice: 'Sector regeneration queued. Visited parsecs will be preserved.'
  end

  def populate_empty
    PopulateEmptySectorsJob.perform_later
    redirect_to campaign_settings_path, notice: 'Empty sector population queued.'
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
    scalar_passenger_dm_settings = Campaign::PASSENGER_DM_SETTINGS - [:passenger_dm_population]
    scalar_freight_dm_settings = Campaign::FREIGHT_DM_SETTINGS - [:freight_dm_population, :freight_dm_tech_level]

    params.expect(campaign: [:name, :campaign_type, :sector_source, :exploration, :sophont_check, :max_tech_level, :native_tech_level, :allow_captive_government, :orbit_distance_display, :realisticStarDistribution, :default_language, :date_format,
                              :local_broker_level, :local_broker_fee_percentage,
                              :sector_capital_colour, :subsector_capital_colour, :hex_size,
                              *scalar_passenger_dm_settings, { passenger_dm_population: [] },
                              *scalar_freight_dm_settings, { freight_dm_population: [], freight_dm_tech_level: [] },
                              *Campaign::MAIL_DM_SETTINGS])
  end
end
