# frozen_string_literal: true

class CommerceController < ApplicationController
  include TwoSystemMapBuildable

  TABS = %w[passage freight mail trade].freeze

  def show
    @tab = TABS.include?(params[:tab]) ? params[:tab] : 'passage'

    @from_system = StarSystem.find_by(id: params[:from_id])
    @to_system   = StarSystem.find_by(id: params[:to_id])

    @passage_broker_effect       = params[:passage_broker_effect].presence&.to_i || 0
    @passage_chief_steward_skill = params[:passage_chief_steward_skill].presence&.to_i || 0
    @passage_referee_modifier    = params[:passage_referee_modifier].presence&.to_i || 0
    @freight_broker_effect       = params[:freight_broker_effect].presence&.to_i || 0
    @freight_referee_modifier    = params[:freight_referee_modifier].presence&.to_i || 0
    @mail_ship_armed             = ActiveModel::Type::Boolean.new.cast(params[:mail_ship_armed])
    @mail_naval_or_scout_rank    = params[:mail_naval_or_scout_rank].presence&.to_i || 0
    @mail_soc_dm                 = params[:mail_soc_dm].presence&.to_i || 0
    @mail_referee_modifier       = params[:mail_referee_modifier].presence&.to_i || 0
    @trade_purchase_skill_effect = params[:trade_purchase_skill_effect].presence&.to_i || 0
    @trade_purchase_broker_skill = params[:trade_purchase_broker_skill].presence&.to_i || 2
    @trade_purchase_other_dm     = params[:trade_purchase_other_dm].presence&.to_i || 0
    @trade_purchase_use_broker   = ActiveModel::Type::Boolean.new.cast(params[:trade_purchase_use_broker])
    @trade_purchase_broker_level = params[:trade_purchase_broker_level].presence&.to_i || current_campaign.local_broker_level_value
    @trade_purchase_broker_fee_percentage = params[:trade_purchase_broker_fee_percentage].presence&.to_f || current_campaign.local_broker_fee_percentage_value
    @trade_sale_skill_effect     = params[:trade_sale_skill_effect].presence&.to_i || 0
    @trade_sale_broker_skill     = params[:trade_sale_broker_skill].presence&.to_i || 2
    @trade_sale_other_dm         = params[:trade_sale_other_dm].presence&.to_i || 0
    @trade_sale_use_broker       = ActiveModel::Type::Boolean.new.cast(params[:trade_sale_use_broker])
    @trade_sale_broker_level     = params[:trade_sale_broker_level].presence&.to_i || current_campaign.local_broker_level_value
    @trade_sale_broker_fee_percentage = params[:trade_sale_broker_fee_percentage].presence&.to_f || current_campaign.local_broker_fee_percentage_value

    passage_dms = PassengerTrafficDms.for(current_campaign)
    freight_dms = FreightTrafficDms.for(current_campaign)

    if @from_system
      @from_passage_modifiers = PassengerTrafficCalculator.world_modifiers(@from_system, passage_dms)
      @from_freight_modifiers = FreightTrafficCalculator.world_modifiers(@from_system, freight_dms)
    end

    if @to_system
      @to_passage_modifiers = PassengerTrafficCalculator.world_modifiers(@to_system, passage_dms)
      @to_freight_modifiers = FreightTrafficCalculator.world_modifiers(@to_system, freight_dms)
    end

    return unless @from_system && @to_system

    if @from_system == @to_system
      flash.now[:alert] = 'Origin and destination must be different systems.'
      return
    end

    @passage_calculator = PassengerTrafficCalculator.new(
      from_system:          @from_system,
      to_system:            @to_system,
      campaign:             current_campaign,
      broker_effect:        @passage_broker_effect,
      chief_steward_skill:  @passage_chief_steward_skill,
      referee_modifier:     @passage_referee_modifier
    ).calculate

    @freight_calculator = FreightTrafficCalculator.new(
      from_system:      @from_system,
      to_system:        @to_system,
      campaign:         current_campaign,
      broker_effect:    @freight_broker_effect,
      referee_modifier: @freight_referee_modifier
    ).calculate

    @mail_calculator = MailCalculator.new(
      from_system:         @from_system,
      to_system:           @to_system,
      campaign:            current_campaign,
      ship_armed:          @mail_ship_armed,
      naval_or_scout_rank: @mail_naval_or_scout_rank,
      soc_dm:              @mail_soc_dm,
      referee_modifier:    @mail_referee_modifier
    ).calculate

    calculate_trade

    build_two_system_map_svg(@from_system.parsec, @to_system.parsec)
  end

  private

  # The goods-available list is re-rolled from @trade_seed on every submit, so it
  # stays stable across the page's repeated full-page GET reloads as long as
  # trade_seed keeps resubmitting via its hidden field — only the "Re-Survey"
  # button (trade_resurvey) mints a fresh one. Purchase/Sale price rolls are
  # always fresh (never seeded) and roll every relevant good in one pass, since
  # the manual inputs (Skill Effect, Broker Skill, Other DM) never vary by good —
  # Purchase is scoped to the surveyed availability list, Sale to every priceable
  # good, since the Travellers may be selling cargo bought anywhere.
  def calculate_trade
    @trade_seed = if params[:trade_resurvey].present?
                    SecureRandom.random_number(1_000_000_000)
    else
                    params[:trade_seed].presence&.to_i || SecureRandom.random_number(1_000_000_000)
    end

    @trade_availability = TradeAvailabilityCalculator.new(
      system: @from_system, campaign: current_campaign, seed: @trade_seed
    ).calculate

    if params[:trade_purchase_submit].present?
      purchase_d66s = @trade_availability.goods.filter_map { |good| good[:d66] unless good[:base_price].nil? }
      @trade_purchase_results = roll_prices(
        d66s:                     purchase_d66s,
        system:                   @from_system,
        direction:                :purchase,
        skill_effect:             @trade_purchase_skill_effect,
        counterpart_broker_skill: @trade_purchase_broker_skill,
        other_dm:                 @trade_purchase_other_dm,
        use_broker:               @trade_purchase_use_broker,
        broker_level:             @trade_purchase_broker_level,
        broker_fee_percentage:    @trade_purchase_broker_fee_percentage
      )
    end

    if params[:trade_sale_submit].present?
      @trade_sale_results = roll_prices(
        d66s:                     TradeGoodsTable.priceable_d66_codes,
        system:                   @to_system,
        direction:                :sale,
        skill_effect:             @trade_sale_skill_effect,
        counterpart_broker_skill: @trade_sale_broker_skill,
        other_dm:                 @trade_sale_other_dm,
        use_broker:               @trade_sale_use_broker,
        broker_level:             @trade_sale_broker_level,
        broker_fee_percentage:    @trade_sale_broker_fee_percentage
      )
    end
  rescue ArgumentError => e
    flash.now[:alert] = e.message
  end

  def roll_prices(d66s:, system:, direction:, skill_effect:, counterpart_broker_skill:, other_dm:, use_broker:,
                   broker_level:, broker_fee_percentage:)
    d66s.index_with do |d66|
      TradePriceCalculator.new(
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
    end
  end

  # Used only for the shared picker's live JS preview before the form is submitted —
  # the rendered tab panels below get their own modifier breakdown regardless of tab.
  def tab_system_data_url
    case @tab
    when 'passage' then api_passenger_traffic_system_path
    when 'freight', 'mail', 'trade' then api_freight_traffic_system_path
    end
  end
  helper_method :tab_system_data_url
end
