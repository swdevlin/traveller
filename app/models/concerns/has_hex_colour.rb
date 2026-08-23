# frozen_string_literal: true

module HasHexColour
  extend ActiveSupport::Concern

  HEX_COLOUR_REGEX = /\A#[0-9a-fA-F]{6}\z/

  class_methods do
    def validates_hex_colour(*attributes, message: 'must be a hex colour (#rrggbb)', **options)
      validates(*attributes, format: { with: HasHexColour::HEX_COLOUR_REGEX, message: message }, **options)
    end
  end
end
