# frozen_string_literal: true

# Referee-only: which neighbouring worlds make good trade partners for a system.
class Api::TradeSynergiesController < Api::BaseController
  MAX_JUMP = 6

  before_action :authenticate_user_or_token!

  def show
    system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'star system not found' }, status: :not_found unless system

    jump = params[:jump].presence&.to_i&.clamp(1, MAX_JUMP) || 2
    partners = TradeSynergyCalculator.partners_within(system, jump)

    render json: { jump: jump }.merge(TradeSynergyCalculator.new(origin: system, partners: partners).calculate)
  end
end
