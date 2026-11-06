# frozen_string_literal: true

class TradeSettingsController < ApplicationController
  def edit
    @campaign = current_campaign
  end

  def update
    @campaign = current_campaign
    if @campaign.update(trade_settings_params)
      redirect_to edit_trade_settings_path, notice: 'Trade & passenger settings updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def trade_settings_params
    scalar_passenger_dm_settings = Campaign::PASSENGER_DM_SETTINGS - [:passenger_dm_population]
    scalar_freight_dm_settings = Campaign::FREIGHT_DM_SETTINGS - [:freight_dm_population, :freight_dm_tech_level]

    params.expect(campaign: [:local_broker_level, :local_broker_fee_percentage,
                              *scalar_passenger_dm_settings, { passenger_dm_population: [] },
                              *scalar_freight_dm_settings, { freight_dm_population: [], freight_dm_tech_level: [] },
                              *Campaign::MAIL_DM_SETTINGS])
  end
end
