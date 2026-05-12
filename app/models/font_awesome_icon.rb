# frozen_string_literal: true

class FontAwesomeIcon < ApplicationRecord
  validates :name, presence: true, format: { with: /\Afa-[a-z0-9-]+\z/ }
  validates :style, presence: true
  validates :view_box, :svg_content, presence: true

  def self.cached_for(name, style: 'regular')
    find_by(name:, style:) ||
      create_from_font_awesome!(name, style:)
  end

  def self.create_from_font_awesome!(name, style:)
    attrs = FontAwesomeIconFetcher.call(name, style:)

    create!(
      name: attrs[:name],
      style: style,
      view_box: attrs[:view_box],
      svg_content: attrs[:svg_content]
    )
  end
end
