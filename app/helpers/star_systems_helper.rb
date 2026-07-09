module StarSystemsHelper
  def format_period(period)
    return if period.nil?

    if period > 730
      years = period / 365.25
      "#{number_with_precision(years, precision: 1, strip_insignificant_zeros: true)} y"
    else
      "#{number_with_precision(period, precision: 1, strip_insignificant_zeros: true)} d"
    end
  end
end
