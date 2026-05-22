# frozen_string_literal: true

class JumpRoute < ApplicationRecord
  LINE_STYLES = %w[solid dashed dotted dash_dot dash_dot_dot long_dash short_dash].freeze

  validates :name,       presence: true
  validates :line_style, inclusion: { in: LINE_STYLES }
  validates :line_width, numericality: { only_integer: true, greater_than: 0 }

  has_many :jump_route_links, dependent: :destroy

  scope :ordered, -> { order(:name) }

  def stroke_dasharray
    case line_style
    when 'dashed'       then '16,8'
    when 'dotted'       then '3,5'
    when 'dash_dot'     then '16,6,3,6'
    when 'dash_dot_dot' then '16,6,3,6,3,6'
    when 'long_dash'    then '28,10'
    when 'short_dash'   then '8,6'
    end
  end
end
