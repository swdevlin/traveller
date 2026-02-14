module ApplicationHelper
  def format_precision(value, precision: 2)
    return if value.nil?

    formatted = number_with_precision(value, precision: precision, strip_insignificant_zeros: true)
    if formatted.to_f.zero? && !value.zero?
      number_with_precision(value, precision: 1, significant: true, strip_insignificant_zeros: true)
    else
      formatted
    end
  end
end
