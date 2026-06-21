# frozen_string_literal: true

class AllSectorsMapGenerator
  PIXEL_SIZE = 4
  COLOUR_BACKGROUND = ChunkyPNG::Color.rgb(0, 0, 0)
  COLOUR_STAR        = ChunkyPNG::Color.rgb(140, 140, 140)
  COLOUR_ROUTE       = ChunkyPNG::Color.rgb(255, 100, 0)
  COLOUR_SECTOR_GRID = ChunkyPNG::Color.rgb(60, 60, 60)
  COLOUR_SUB_GRID    = ChunkyPNG::Color.rgb(25, 25, 25)
  LABEL_RGB          = [255, 120, 120].freeze

  def initialize(campaign)
    @campaign = campaign
  end

  def call
    sectors = Sector.kept.to_a
    return if sectors.empty?

    compute_bounds(sectors)
    image = build_image
    draw_sub_grid(image)
    draw_sector_grid(image)
    plot_stars(image)
    plot_routes(image)
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

  def draw_sub_grid(image)
    sub_px_w = 8  * PIXEL_SIZE
    sub_px_h = 10 * PIXEL_SIZE
    (0..@img_width).step(sub_px_w) { |x| draw_vline(image, x, COLOUR_SUB_GRID) }
    (0..@img_height).step(sub_px_h) { |y| draw_hline(image, y, COLOUR_SUB_GRID) }
  end

  def draw_sector_grid(image)
    sector_px_w = 32 * PIXEL_SIZE
    sector_px_h = 40 * PIXEL_SIZE
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

  def plot_stars(image)
    fetch_star_coords.each do |px, py|
      fill_hex(image, px, py, COLOUR_STAR)
    end
  end

  def plot_routes(image)
    fetch_route_coords.each do |px, py|
      fill_hex(image, px, py, COLOUR_ROUTE, size: PIXEL_SIZE)
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

  def fetch_route_coords
    to_coords   = Parsec.where(id: JumpLog.select(:to_parsec_id)).pluck(:x, :y)
    from_coords = Parsec.where(id: JumpLog.select(:from_parsec_id)).pluck(:x, :y)
    Set.new(to_coords + from_coords)
  end

  def fill_hex(image, px, py, colour, size: 2)
    base_x = (px - @min_px) * PIXEL_SIZE
    base_y = (@max_py - py) * PIXEL_SIZE
    size.times do |dx|
      size.times do |dy|
        x = base_x + dx
        y = base_y + dy
        image[x, y] = colour if x >= 0 && y >= 0 && x < @img_width && y < @img_height
      end
    end
  end

  def to_vips(chunky_image)
    img = Vips::Image.new_from_buffer(chunky_image.to_blob, '').copy(interpretation: :srgb)
    img.has_alpha? ? img.flatten(background: [0, 0, 0]) : img
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
      begin
        vips = vips.composite2(label, :over, x: x, y: y)
      rescue Vips::Error => e
        Rails.logger.error(
          'AllSectorsMapGenerator composite2 failed ' \
          "vips_bands=#{vips.bands} vips_format=#{vips.format} vips_interp=#{vips.interpretation} " \
          "label_bands=#{label.bands} label_format=#{label.format} label_interp=#{label.interpretation} " \
          "error=#{e.message}"
        )
      end
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

    # Newer libvips may return RGBA from vips_text; extract just the alpha band
    alpha = text_mask.bands == 1 ? text_mask : text_mask.extract_band(text_mask.bands - 1)
    fg_rgb = alpha.new_from_image(LABEL_RGB).copy(interpretation: :srgb)
    fg_rgb.bandjoin(alpha)
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
