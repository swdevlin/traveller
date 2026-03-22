module ApplicationHelper
  def show_au?
    current_campaign&.show_orbit_number? != true
  end

  def show_orbit_number?
    current_campaign&.show_orbit_number? == true
  end

  def signed_map_url(path)
    uri = URI.parse(path)
    token = current_campaign.token_for(uri.path)
    separator = uri.query.present? ? '&' : '?'
    "#{request.base_url}#{path}#{separator}token=#{token}"
  end

  def contextual_help_path
    candidates = ["#{controller_name}_#{action_name}", controller_name]
    page = candidates.find { |name| lookup_context.template_exists?("help/#{name}", [], false) }
    page ? help_page_path(page) : help_path
  end

  def required_icon(model, attribute)
    validators = model.class.validators_on(attribute)
    return unless validators.any? { |v| v.is_a?(ActiveRecord::Validations::PresenceValidator) }

    tag.i(class: 'fa-thin fa-microchip ml-1 align-middle', aria: { hidden: true })
  end

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
