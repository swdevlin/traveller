# frozen_string_literal: true

class JumpRoute < ApplicationRecord
  LINE_STYLES = %w[solid dashed dotted].freeze

  validates :name,       presence: true
  validates :line_style, inclusion: { in: LINE_STYLES }
  validates :line_width, numericality: { only_integer: true, greater_than: 0 }

  has_many :jump_route_links, dependent: :destroy

  scope :ordered, -> { order(:name) }

  def stroke_dasharray
    case line_style
    when 'dashed' then '16,8'
    when 'dotted' then '3,5'
    end
  end
end
