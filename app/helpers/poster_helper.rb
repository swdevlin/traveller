module PosterHelper
  LEGEND_ICON_SIZE  = 6.5
  LEGEND_ICON_GAP   = 2.0
  LEGEND_ITEM_H     = 8.5
  LEGEND_FONT_SIZE  = 4.0
  LEGEND_CHAR_W     = 3.0

  class LegendCursor
    attr_reader :x, :y

    def initialize(x, start_y, max_y)
      @x, @y = x, start_y
      @start_y, @max_y = start_y, max_y
      @col_max_w = 0
    end

    def advance(item_h, item_w)
      @col_max_w = [@col_max_w, item_w].max
      @y += item_h
      if @y > @max_y
        @x += @col_max_w + 2
        @y = @start_y
        @col_max_w = 0
      end
    end
  end

  def add_legend_item(cursor, icon_svg, label)
    ix       = cursor.x.round(1)
    center_y = (cursor.y + LEGEND_ITEM_H / 2.0).round(1)
    text_dx  = (LEGEND_ICON_SIZE + LEGEND_ICON_GAP).round(1)

    cursor.advance(LEGEND_ITEM_H, LEGEND_ICON_SIZE + LEGEND_ICON_GAP + label.length * LEGEND_CHAR_W)

    text_y = (LEGEND_FONT_SIZE * 0.35).round(3)
    %(<g transform="translate(#{ix},#{center_y})">#{icon_svg}<text class="p-legend" font-size="#{LEGEND_FONT_SIZE}" x="#{text_dx}" y="#{text_y}">#{h(label)}</text></g>).html_safe
  end
end
