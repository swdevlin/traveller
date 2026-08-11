# frozen_string_literal: true

# Referee-only tool — no player-visible variant exists for speculative trade.
class Api::TradeGoodsController < Api::BaseController
  before_action :authenticate_user_or_token!

  # Rolls (or re-derives, given a seed) the list of goods available for purchase
  # at a system. Callers should hold onto the returned +seed+ and pass it back on
  # subsequent requests to keep the same list stable; omit it to roll a fresh one.
  def availability
    system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'id must reference a star system' }, status: :unprocessable_entity unless system

    seed = params[:seed].presence&.to_i || SecureRandom.random_number(1_000_000_000)
    calculator = TradeAvailabilityCalculator.new(system: system, campaign: current_campaign, seed: seed).calculate

    render json: {
      system: system_json(system),
      trade_codes: calculator.trade_codes,
      population: calculator.population,
      seed: seed,
      goods: calculator.goods
    }
  end

  # Rolls Purchase or Sale price for every good in +d66s+ (or, if omitted, every
  # priceable good) in a single request — the manual inputs (Skill Effect,
  # counterpart Broker Skill, Other DM) never vary by good, so there is no
  # reason to roll one good at a time.
  def prices
    system = StarSystem.find_by(id: params[:id])
    return render json: { error: 'id must reference a star system' }, status: :unprocessable_entity unless system

    skill_effect             = params[:skill_effect].presence&.to_i || 0
    counterpart_broker_skill = params[:counterpart_broker_skill].presence&.to_i || 2
    other_dm                 = params[:other_dm].presence&.to_i || 0
    use_broker                = ActiveModel::Type::Boolean.new.cast(params[:use_broker])
    broker_level              = params[:broker_level].presence&.to_i || current_campaign.local_broker_level_value
    broker_fee_percentage      = params[:broker_fee_percentage].presence&.to_f || current_campaign.local_broker_fee_percentage_value
    direction                = params[:direction]
    d66s                     = Array(params[:d66s]).map(&:to_i).presence || TradeGoodsTable.priceable_d66_codes

    results = d66s.map do |d66|
      calculator = TradePriceCalculator.new(
        d66:                      d66,
        system:                   system,
        campaign:                 current_campaign,
        direction:                direction,
        skill_effect:             skill_effect,
        counterpart_broker_skill: counterpart_broker_skill,
        other_dm:                 other_dm,
        use_broker:               use_broker,
        broker_level:             broker_level,
        broker_fee_percentage:    broker_fee_percentage
      ).calculate

      { d66: calculator.good[:d66], name: calculator.good[:name], modifiers: calculator.modifiers,
        result: result_json(calculator.result) }
    end

    render json: {
      system:                   system_json(system),
      direction:                direction,
      skill_effect:             skill_effect,
      counterpart_broker_skill: counterpart_broker_skill,
      other_dm:                 other_dm,
      use_broker:               use_broker,
      broker_level:             broker_level,
      broker_fee_percentage:    broker_fee_percentage,
      results:                  results
    }
  rescue ArgumentError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def system_json(system)
    { id: system.id, name: system.name }
  end

  def result_json(result)
    {
      base_price:        result[:base_price],
      percent:           result[:percent],
      price_per_ton:     result[:price_per_ton],
      net_price_per_ton: result[:net_price_per_ton],
      fee_percentage:    result[:fee_percentage],
      qualifying_roll:   roll_json(result[:qualifying_roll])
    }
  end

  def roll_json(roll)
    { dice: roll[:dice], sides: roll[:sides], dm: roll[:dm], rolls: roll[:rolls], total: roll[:total] }
  end
end
