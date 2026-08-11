# frozen_string_literal: true

# Referee-only tool — no player-visible variant exists for freight traffic.
class Api::FreightTrafficController < Api::BaseController
  before_action :authenticate_user_or_token!

  # UWP + DM breakdown for a single system, with no role suffix on the labels —
  # used to show a system's data as soon as it's picked, before its counterpart
  # is selected.
  def system
    system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'id must reference a star system' }, status: :unprocessable_entity unless system

    dms = FreightTrafficDms.for(current_campaign)
    render json: {
      uwp:          system.main_world_uwp,
      trade_codes:  system.trade_codes.order(:code).pluck(:code),
      travel_zone:  system.travel_zone&.code,
      modifiers:    FreightTrafficCalculator.world_modifiers(system, dms)
    }
  end

  def calculate
    from_system = StarSystem.find_by(id: params[:from_id])
    to_system   = StarSystem.find_by(id: params[:to_id])
    unless from_system && to_system && from_system != to_system
      return render json: { error: 'from_id and to_id must reference two different star systems' },
                    status: :unprocessable_entity
    end

    broker_effect    = params[:broker_effect].presence&.to_i || 0
    referee_modifier = params[:referee_modifier].presence&.to_i || 0

    calculator = FreightTrafficCalculator.new(
      from_system:      from_system,
      to_system:        to_system,
      campaign:         current_campaign,
      broker_effect:    broker_effect,
      referee_modifier: referee_modifier
    ).calculate

    render json: {
      from:              system_json(from_system),
      to:                system_json(to_system),
      parsec_distance:   calculator.parsec_distance,
      broker_effect:     broker_effect,
      referee_modifier:  referee_modifier,
      shared_modifiers:  calculator.shared_modifiers,
      lot_types:         FreightTrafficCalculator::LOT_TYPES.index_with { |type| lot_type_json(calculator.results[type]) }
    }
  end

  private

  def system_json(system)
    { id: system.id, name: system.name }
  end

  def lot_type_json(result)
    {
      lots:             result[:lots],
      total_tons:       result[:total_tons],
      modifiers:         result[:modifiers],
      qualifying_roll:   roll_json(result[:qualifying_roll]),
      lots_roll:         result[:lots_roll] ? roll_json(result[:lots_roll]) : nil,
      lot_size_rolls:    result[:lot_size_rolls].map { |roll| roll_json(roll).merge(tons: roll[:tons]) }
    }
  end

  def roll_json(roll)
    { dice: roll[:dice], sides: roll[:sides], dm: roll[:dm], rolls: roll[:rolls], total: roll[:total] }
  end
end
