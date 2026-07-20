# frozen_string_literal: true

module HexMapParsecLabels
  extend ActiveSupport::Concern

  private

  # `sector_ul` is only needed for subsector actions, where `hex_code` is expressed in
  # sector-relative coordinates while `col`/`row` are subsector-relative.
  def build_parsecs_by_pos(parsec_scope, ul, sector_ul: ul)
    parsec_scope.pluck(:id, :x, :y, :label, :label_colour, :icon_class, :visible, :known)
                .to_h do |pid, px, py, lbl, colour, icon, vis, known|
      col = px - ul.x + 1
      row = ul.y - py + 1
      hex_code = format('%02d%02d', px - sector_ul.x + 1, sector_ul.y - py + 1)
      show = vis && (authenticated? || known)

      [[col, row], {
        id: pid,
        hex_code: hex_code,
        label: show ? lbl : nil,
        label_colour: show ? colour : nil,
        icon_class: show ? icon : nil
      }]
    end
  end

  def build_parsec_label_icons(parsecs_by_pos)
    icon_classes = parsecs_by_pos.values.filter_map { |v| v[:icon_class].presence }.uniq
    return {} if icon_classes.empty?

    parsed = icon_classes.filter_map do |ic|
      parts = ic.split(' ')
      { icon_class: ic, name: parts[1], style: parts[0].delete_prefix('fa-') }
    end

    icons = FontAwesomeIcon
      .where(name: parsed.map { |p| p[:name] }.uniq)
      .index_by { |i| [i.name, i.style] }

    parsed.each_with_object({}) do |p, h|
      icon = icons[[p[:name], p[:style]]]
      h[p[:icon_class]] = icon if icon
    end
  end
end
