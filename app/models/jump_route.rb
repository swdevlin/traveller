# frozen_string_literal: true

class JumpRoute < ApplicationRecord
  LINE_STYLES = %w[solid dashed dotted dash_dot dash_dot_dot long_dash short_dash].freeze

  validates :name,       presence: true
  validates :line_style, inclusion: { in: LINE_STYLES }
  validates :line_width, numericality: { only_integer: true, greater_than: 0 }

  has_many :jump_route_links, dependent: :destroy

  SECTOR_COLS = 32
  SECTOR_ROWS = 40

  scope :ordered, -> { order(:name) }

  def fits_in_sector?
    system_ids = jump_route_links.pluck(:from_star_system_id, :to_star_system_id).flatten.uniq
    return false if system_ids.empty?

    min_x, max_x, min_y, max_y = Parsec
      .joins(:star_systems)
      .where(star_systems: { id: system_ids })
      .pick(Arel.sql('MIN(parsecs.x), MAX(parsecs.x), MIN(parsecs.y), MAX(parsecs.y)'))

    return false if min_x.nil?
    (max_x - min_x + 1) <= SECTOR_COLS && (max_y - min_y + 1) <= SECTOR_ROWS
  end

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
