# frozen_string_literal: true

# Drawing primitives for the star system handout pages. Positions are millimetres. A Block is a
# group of primitives positioned relative to its own top left corner, so blocks can be built
# without knowing where on the page they will land, then translated into place.
class HandoutCanvas
  module Translatable
    def translate(dx, dy)
      moved = dup
      moved.x += dx
      moved.y += dy
      moved
    end
  end

  Text = Struct.new(:x, :y, :size, :text, :font, :fill, :weight, :italic, :strike, :underline, :anchor, :spacing,
                    keyword_init: true) do
    include Translatable
  end

  Rect = Struct.new(:x, :y, :width, :height, :fill, :stroke, :stroke_width, keyword_init: true) do
    include Translatable
  end

  Image = Struct.new(:x, :y, :width, :height, :href, keyword_init: true) do
    include Translatable
  end

  # The system subway map, drawn by the view from its StarSystemMapLayout. view_box is the part of
  # the layout's own coordinate space to show: [x, y, width, height].
  Subway = Struct.new(:x, :y, :width, :height, :layout, :view_box, keyword_init: true) do
    include Translatable
  end

  Block = Struct.new(:items, :height) do
    def self.empty = new([], 0)

    def translated(dx, dy)
      items.map { |item| item.translate(dx, dy) }
    end
  end
end
