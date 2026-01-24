module StellarObjectsHelper
  def temperature_label(temperature)
    return '' if temperature.nil?
    if temperature > 40
      'Hot'
    elsif temperature < 0
      'Freezing'
    end
  end
end
