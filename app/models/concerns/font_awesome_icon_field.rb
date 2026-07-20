module FontAwesomeIconField
  extend ActiveSupport::Concern

  included do
    validates :icon_class,
              allow_blank: true,
              format: { with: /\Afa-[a-z]+ fa-[a-z0-9-]+\z/, message: 'must be in the format fa-solid fa-star' }

    validate :icon_must_be_valid, if: -> { icon_class.present? && icon_class_changed? && errors[:icon_class].empty? }
  end

  def icon
    return nil if icon_class.blank?

    FontAwesomeIcon.cached_for(icon_name, style: icon_style)
  end

  private

  def icon_name
    icon_class.split(' ')[1]
  end

  def icon_style
    icon_class.split(' ')[0].delete_prefix('fa-')
  end

  def icon_must_be_valid
    FontAwesomeIcon.cached_for(icon_name, style: icon_style)
  rescue FontAwesomeIconFetcher::NotFound, FontAwesomeIconFetcher::Error
    errors.add(:icon_class, 'is not a valid Font Awesome icon')
  end
end
