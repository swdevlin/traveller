# frozen_string_literal: true

# Referee-only tool — no player-visible variant exists for mail traffic.
class Api::MailTrafficController < Api::BaseController
  before_action :authenticate_user_or_token!

  # UWP + Freight Traffic DM breakdown for a single system, with no role suffix on the
  # labels — used to show a system's data as soon as it's picked, before its counterpart
  # is selected. Mail's qualifying roll is keyed off the same Freight Traffic DM.
  def system
    system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'id must reference a star system' }, status: :unprocessable_entity unless system

    dms = FreightTrafficDms.for(current_campaign)
    render json: { uwp: system.main_world_uwp, modifiers: FreightTrafficCalculator.world_modifiers(system, dms) }
  end

  def calculate
    from_system = StarSystem.find_by(id: params[:from_id])
    to_system   = StarSystem.find_by(id: params[:to_id])
    unless from_system && to_system && from_system != to_system
      return render json: { error: 'from_id and to_id must reference two different star systems' },
                    status: :unprocessable_entity
    end

    ship_armed          = ActiveModel::Type::Boolean.new.cast(params[:ship_armed])
    naval_or_scout_rank = params[:naval_or_scout_rank].presence&.to_i || 0
    soc_dm              = params[:soc_dm].presence&.to_i || 0
    referee_modifier    = params[:referee_modifier].presence&.to_i || 0

    calculator = MailCalculator.new(
      from_system:         from_system,
      to_system:           to_system,
      campaign:            current_campaign,
      ship_armed:          ship_armed,
      naval_or_scout_rank: naval_or_scout_rank,
      soc_dm:              soc_dm,
      referee_modifier:    referee_modifier
    ).calculate

    render json: {
      from:                system_json(from_system),
      to:                  system_json(to_system),
      parsec_distance:     calculator.parsec_distance,
      freight_traffic_dm:  calculator.freight_traffic_dm,
      ship_armed:          ship_armed,
      naval_or_scout_rank: naval_or_scout_rank,
      soc_dm:              soc_dm,
      referee_modifier:    referee_modifier,
      modifiers:           calculator.modifiers,
      result:              result_json(calculator.result)
    }
  end

  private

  def system_json(system)
    { id: system.id, name: system.name }
  end

  def result_json(result)
    {
      available:        result[:available],
      containers:        result[:containers],
      total_tons:        result[:total_tons],
      total_payment:     result[:total_payment],
      qualifying_roll:   roll_json(result[:qualifying_roll]),
      containers_roll:   result[:containers_roll] ? roll_json(result[:containers_roll]) : nil
    }
  end

  def roll_json(roll)
    { dice: roll[:dice], sides: roll[:sides], dm: roll[:dm], rolls: roll[:rolls], total: roll[:total] }
  end
end
