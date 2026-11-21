# frozen_string_literal: true

# House rule: the Bilateral Trade Number (BTN) rates how much trade is likely
# between two worlds. It is the number of goods flowing in each direction plus
# a die modifier for each world's WTN and xenophilia, and one for the distance.
# Pure arithmetic: see TradeSynergyCalculator for where the goods come from.
class BilateralTradeNumber
  DISTANCE_DMS = { 1 => 0, 2 => 0, 3 => -1, 4 => -2, 5 => -4 }.freeze
  FAR_DISTANCE_DM = -6

  # [minimum WTN, DM], checked from the highest down.
  WTN_DMS = [[13, 4], [11, 3], [9, 2], [6, 1], [0, 0]].freeze

  # [minimum BTN, classification], checked from the highest down.
  CLASSIFICATIONS = [
    [35, 'Very High'], [19, 'High'], [7, 'Moderate'],
    [1, 'Low'], [0, 'Opportunistic']
  ].freeze

  def self.wtn_dm(wtn)
    return 0 if wtn.nil?

    WTN_DMS.find { |minimum, _| wtn.floor >= minimum }.last
  end

  def self.distance_dm(distance)
    DISTANCE_DMS.fetch(distance, FAR_DISTANCE_DM)
  end

  # Xenophilia as a signed cultural trait DM (see CultureTraitDm): a xenophobic world is negative.
  def self.xeno_dm(xenophilia)
    CultureTraitDm.signed(xenophilia) || 0
  end

  def self.tradable?(goods, *wtns)
    goods.positive? && wtns.none? { it&.zero? }
  end
  private_class_method :tradable?

  def self.classification(btn)
    CLASSIFICATIONS.find { |minimum, _| btn >= minimum }.last
  end

  # The BTN is 0 when no goods flow in either direction or either WTN is 0, and is never below 0.
  # @return [Hash] { value:, classification:, exports:, imports:, source_wtn_dm:,
  #   destination_wtn_dm:, distance_dm:, source_xeno_dm:, destination_xeno_dm: }
  def self.calculate(exports:, imports:, distance:, source_wtn:, destination_wtn:,
                     source_xenophilia: nil, destination_xenophilia: nil)
    parts = {
      exports: exports,
      imports: imports,
      source_wtn_dm: wtn_dm(source_wtn),
      destination_wtn_dm: wtn_dm(destination_wtn),
      distance_dm: distance_dm(distance),
      source_xeno_dm: xeno_dm(source_xenophilia),
      destination_xeno_dm: xeno_dm(destination_xenophilia)
    }
    value = tradable?(exports + imports, source_wtn, destination_wtn) ? [parts.values.sum, 0].max : 0
    parts.merge(value: value, classification: classification(value))
  end
end
