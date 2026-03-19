# frozen_string_literal: true

class AllSectorsMapGenerator
  PIXEL_SIZE = 4
  COLOUR_BACKGROUND = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOUR_STAR        = ChunkyPNG::Color.rgb(140, 140, 140)
  COLOUR_VISITED     = ChunkyPNG::Color.rgb(255, 140, 0)
  COLOUR_SECTOR_GRID = ChunkyPNG::Color.rgb(60, 60, 60)
  COLOUR_SUB_GRID    = ChunkyPNG::Color.rgb(25, 25, 25)
  LABEL_RGB          = [225, 6, 0].freeze

  def initialize(campaign)
    @campaign = campaign
  end

  def call
    sectors = Sector.kept.to_a
    return if sectors.empty?

    compute_bounds(sectors)
    image = build_image
    draw_grid(image)
    plot_hexes(image)
    vips = to_vips(image)
    vips = draw_labels(vips, sectors)
    write_webp(vips)
  end

  def output_path
    dir = Rails.root.join('storage', @campaign.schema_name)
    dir.join('all_sectors.webp')
  end

  private

  def compute_bounds(sectors)
    @min_sx = sectors.map(&:x).min
    @max_sx = sectors.map(&:x).max
    @min_sy = sectors.map(&:y).min
    @max_sy = sectors.map(&:y).max

    @min_px = @min_sx * 32
    @max_py = @max_sy * 40
    @img_width  = (@max_sx - @min_sx + 1) * 32 * PIXEL_SIZE
    @img_height = (@max_sy - @min_sy + 1) * 40 * PIXEL_SIZE
  end

  def build_image
    ChunkyPNG::Image.new(@img_width, @img_height, COLOUR_BACKGROUND)
  end

  def draw_grid(image)
    sector_px_w = 32 * PIXEL_SIZE
    sector_px_h = 40 * PIXEL_SIZE
    sub_px_w    = 8  * PIXEL_SIZE
    sub_px_h    = 10 * PIXEL_SIZE

    # Subsector grid (drawn first, underneath)
    (0..@img_width).step(sub_px_w) { |x| draw_vline(image, x, COLOUR_SUB_GRID) }
    (0..@img_height).step(sub_px_h) { |y| draw_hline(image, y, COLOUR_SUB_GRID) }

    # Sector grid (drawn on top)
    (0..@img_width).step(sector_px_w) { |x| draw_vline(image, x, COLOUR_SECTOR_GRID) }
    (0..@img_height).step(sector_px_h) { |y| draw_hline(image, y, COLOUR_SECTOR_GRID) }
  end

  def draw_vline(image, x, colour)
    return unless x < @img_width

    (0...@img_height).each { |y| image[x, y] = colour }
  end

  def draw_hline(image, y, colour)
    return unless y < @img_height

    (0...@img_width).each { |x| image[x, y] = colour }
  end

  def plot_hexes(image)
    star_coords    = fetch_star_coords
    visited_coords = fetch_visited_coords

    star_coords.each do |px, py|
      fill_hex(image, px, py, COLOUR_STAR)
    end
    visited_coords.each do |px, py|
      fill_hex(image, px, py, COLOUR_VISITED, size: 3)
    end
  end

  def fetch_star_coords
    Set.new(
      Parsec.joins(:star_systems)
            .where('star_systems.survey_index > 0')
            .distinct
            .pluck(:x, :y)
    )
  end

  def fetch_visited_coords
    to_coords   = Parsec.joins('INNER JOIN jump_logs ON jump_logs.to_parsec_id = parsecs.id').distinct.pluck(:x, :y)
    from_coords = Parsec.joins('INNER JOIN jump_logs ON jump_logs.from_parsec_id = parsecs.id').distinct.pluck(:x, :y)
    Set.new(to_coords + from_coords)
  end

  def fill_hex(image, px, py, colour, size: 2)
    base_x = (px - @min_px) * PIXEL_SIZE + 1
    base_y = (@max_py - py) * PIXEL_SIZE + 1
    size.times do |dx|
      size.times do |dy|
        x = base_x + dx
        y = base_y + dy
        image[x, y] = colour if x >= 0 && y >= 0 && x < @img_width && y < @img_height
      end
    end
  end

  def to_vips(chunky_image)
    Vips::Image.new_from_buffer(chunky_image.to_blob, '').copy(interpretation: :srgb)
  end

  def draw_labels(vips, sectors)
    vips = vips.add_alpha

    sectors.each do |sector|
      next if sector.name.blank?

      lx = (sector.x - @min_sx) * 32 * PIXEL_SIZE + (16 * PIXEL_SIZE)
      ly = (@max_sy - sector.y) * 40 * PIXEL_SIZE + (20 * PIXEL_SIZE)

      label = render_label(sector.name)
      next unless label

      x = lx - label.width  / 2
      y = ly - label.height / 2
      vips = vips.composite2(label, :over, x: x, y: y)
    end

    vips
  end

  def balance_wrap(name)
    words = name.split
    return name if words.length == 1 || name.length <= 12

    best_split = 1
    best_diff  = Float::INFINITY
    (1...words.length).each do |i|
      diff = (words[0, i].join(' ').length - words[i..].join(' ').length).abs
      if diff < best_diff
        best_diff  = diff
        best_split = i
      end
    end

    [words[0, best_split].join(' '), words[best_split..].join(' ')].join("\n")
  end

  def render_label(name)
    text_mask = Vips::Image.text(balance_wrap(name), font: 'sans 10', dpi: 96, align: :centre)
    return nil if text_mask.width.zero? || text_mask.height.zero?

    padding = 3
    w = text_mask.width + (padding * 2)
    h = text_mask.height + (padding * 2)

    bg_rgb   = Vips::Image.black(w, h).new_from_image([0, 0, 0]).copy(interpretation: :srgb)
    bg_alpha = Vips::Image.black(w, h).new_from_image(160)
    bg_rgba  = bg_rgb.bandjoin(bg_alpha)

    fg_rgb  = text_mask.new_from_image(LABEL_RGB).copy(interpretation: :srgb)
    fg_rgba = fg_rgb.bandjoin(text_mask)

    bg_rgba.composite2(fg_rgba, :over, x: padding, y: padding)
  rescue Vips::Error
    nil
  end

  def write_webp(vips)
    dir = output_path.dirname
    FileUtils.mkdir_p(dir)
    vips.flatten(background: [0, 0, 0]).webpsave(output_path.to_s)
    output_path
  end
end
