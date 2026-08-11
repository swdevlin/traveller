# frozen_string_literal: true

module FreightTrafficsHelper
  def freight_roll_description(roll)
    "#{roll[:dice]}D#{roll[:sides]}#{format('%+d', roll[:dm]) if roll[:dm] != 0} " \
      "[#{roll[:rolls].join(', ')}] = #{roll[:total]}"
  end

  def freight_modifier_description(modifier)
    "#{modifier[:label]} (#{format('%+d', modifier[:value])})"
  end

  # Combines individually-rolled lot sizes into "N lots of X tons each" groups,
  # largest first — the audit trail (which dice rolled which size) isn't useful
  # to the referee once the lots are found.
  def freight_lot_size_summary(lot_size_rolls)
    lot_size_rolls.group_by { |roll| roll[:tons] }.sort_by { |tons, _| -tons }.map do |tons, rolls|
      rolls.size == 1 ? "1 lot of #{pluralize(tons, 'ton')}" : "#{pluralize(rolls.size, 'lot')} of #{pluralize(tons, 'ton')} each"
    end
  end
end
