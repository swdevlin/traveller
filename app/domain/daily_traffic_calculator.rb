# frozen_string_literal: true

class DailyTrafficCalculator
  attr_reader :effective_importance, :raw_result, :result, :roller, :modifiers, :tier_label

  def initialize(importance:, wtn:, frontier: false)
    @importance = importance.to_i
    @wtn        = wtn.to_f
    @frontier   = frontier
    @roller     = DiceRoller.new
    @modifiers  = []
  end

  def calculate
    effective = @importance

    if @wtn >= 10
      effective += 1
      @modifiers << 'WTN A+ (+1)'
    end

    if @frontier || @wtn <= 4
      effective -= 1
      reasons = []
      reasons << 'Frontier' if @frontier
      reasons << 'WTN ≤ 4'  if @wtn <= 4
      @modifiers << "#{reasons.join('/')} (−1)"
    end

    @effective_importance = effective
    @tier_label           = tier_label_for(effective)
    @raw_result           = roll_traffic(effective)
    @result               = [@raw_result, 0].max
    self
  end

  private

  def tier_label_for(imp)
    case imp
    when (6..)  then 'Exceptional Trade Hub'
    when 5      then 'Very Important'
    when 4      then 'Important'
    when 1..3   then 'Ordinary'
    when 0, -1  then 'Unimportant'
    when -2, -3 then 'Very Unimportant'
    else             'Uncharted'
    end
  end

  def roll_traffic(imp)
    case imp
    when (6..)
      base   = @roller.roll(n: 3, d: 6, dm: 0,  note: '3d6 × 20 base')
      offset = @roller.roll(n: 2, d: 6, dm: -7, note: '2d6−7 offset')
      base * 20 + offset
    when 5
      base   = @roller.roll(n: 3, d: 6, dm: 0,  note: '3d6 × 10 base')
      offset = @roller.roll(n: 2, d: 6, dm: -7, note: '2d6−7 offset')
      base * 10 + offset
    when 4  then @roller.roll(n: 2, d: 6, dm:  10, note: 'Daily traffic')
    when 3  then @roller.roll(n: 2, d: 6, dm:  -5, note: 'Daily traffic')
    when 2  then @roller.roll(n: 1, d: 6, dm:  -2, note: 'Daily traffic')
    when 1  then @roller.roll(n: 1, d: 6, dm:  -3, note: 'Daily traffic')
    when 0  then @roller.roll(n: 1, d: 6, dm:  -4, note: 'Daily traffic')
    when -1 then @roller.roll(n: 1, d: 6, dm:  -5, note: 'Daily traffic')
    when -2, -3 then @roller.roll(n: 2, d: 6, dm: -11, note: 'Daily traffic')
    else         @roller.roll(n: 3, d: 6, dm: -17, note: 'Daily traffic (uncharted)')
    end
  end
end
