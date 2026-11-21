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

    btn = current_campaign.bilateral_trade_number?
    result = TradeSynergyCalculator.new(origin: system, partners: partners, with_btn: btn).calculate
    render json: { jump: jump, btn_help_url: (help_page_path('bilateral_trade_number') if btn) }.merge(result)
  end
end
