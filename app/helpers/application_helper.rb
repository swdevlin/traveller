module ApplicationHelper
  THEMES = {
    'dark' => { label: 'Dark', light: false },
    'light' => { label: 'Light', light: true },
    'aslan' => { label: 'Aslan', light: false },
    'bwap' => { label: 'Bwap', light: true },
    'darrian' => { label: 'Darrian', light: true },
    'deepnight' => { label: 'Deepnight', light: false },
    'droyne' => { label: 'Droyne', light: false },
    'hiver' => { label: 'Hiver', light: false },
    'imperium' => { label: 'Imperium', light: false },
    'kkree' => { label: "K'Kree", light: true },
    'solomani' => { label: 'Solomani', light: false },
    'swordworlds' => { label: 'Sword Worlds', light: false },
    'vargr' => { label: 'Vargr', light: false },
    'vegan' => { label: 'Vegan', light: false },
    'zhodani' => { label: 'Zhodani', light: true }
  }.freeze

  def current_theme
    cookies[:theme].presence || 'dark'
  end

  def current_theme_light?
    THEMES.fetch(current_theme, THEMES['dark'])[:light]
  end

  def show_au?
    current_campaign&.show_orbit_number? != true
  end

  def show_orbit_number?
    current_campaign&.show_orbit_number? == true
  end

  def show_population_count?
    current_campaign&.homebrew? || current_campaign&.deepnight_revelation?
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

  def format_traveller_date(year, day)
    return nil unless year

    day_str = format('%03d', day || 0)
    current_campaign&.traveller_date_format? != false ? "#{day_str}-#{year}" : "#{year}-#{day_str}"
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
