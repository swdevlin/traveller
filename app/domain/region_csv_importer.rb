require 'csv'

class RegionCsvImporter
  def initialize(region, csv_text)
    @region = region
    @csv_text = csv_text
  end

  def call
    rows = parse_rows
    return error('The CSV file is empty.') if rows.empty?

    coords = rows.map { |r| to_universal(r) }

    sector_names = load_sector_names(rows)
    adj_error = adjacency_error(rows, coords, sector_names)
    return error(adj_error) if adj_error

    parsecs = resolve_parsecs(coords)
    missing = parsecs.count(&:nil?)
    return error("#{missing} #{'hex'.pluralize(missing)} could not be found in the database.") if missing > 0

    border_set = coords.to_set
    fill_coords = compute_fill(border_set)

    fill_parsec_map = Parsec
      .where(x: fill_coords.map(&:first), y: fill_coords.map(&:last))
      .index_by { |p| [p.x, p.y] }

    ActiveRecord::Base.transaction do
      @region.region_parsecs.delete_all

      parsecs.each_with_index do |parsec, idx|
        RegionParsec.create!(region: @region, parsec: parsec, kind: 'border', position: idx)
      end

      fill_coords.each do |ux, uy|
        next if border_set.include?([ux, uy])
        p = fill_parsec_map[[ux, uy]]
        RegionParsec.create!(region: @region, parsec: p, kind: 'fill') if p
      end
    end

    { ok: true }
  end

  private

  def parse_rows
    CSV.parse(@csv_text, headers: true, header_converters: :symbol).map do |row|
      { sector_x: row[:sector_x].to_i, sector_y: row[:sector_y].to_i,
        hex_x: row[:hex_x].to_i, hex_y: row[:hex_y].to_i }
    end
  rescue CSV::MalformedCSVError => e
    []
  end

  def to_universal(row)
    ux = row[:sector_x] * 32 + (row[:hex_x] - 1)
    uy = row[:sector_y] * 40 - (row[:hex_y] - 1)
    [ux, uy]
  end

  def adjacency_error(rows, coords, sector_names)
    return nil if coords.size == 1

    row_coord_pairs = rows.zip(coords)
    pairs = row_coord_pairs.each_cons(2).to_a + [[row_coord_pairs.last, row_coord_pairs.first]]
    pairs.each do |(row1, coord1), (row2, coord2)|
      unless neighbours(*coord1).include?(coord2)
        return "Hex #{hex_label(row1, sector_names)} is not adjacent to #{hex_label(row2, sector_names)}."
      end
    end
    nil
  end

  def neighbours(ux, uy)
    if ux.even?
      [[ux + 1, uy], [ux, uy - 1], [ux - 1, uy], [ux - 1, uy + 1], [ux, uy + 1], [ux + 1, uy + 1]]
    else
      [[ux + 1, uy - 1], [ux, uy - 1], [ux - 1, uy - 1], [ux - 1, uy], [ux, uy + 1], [ux + 1, uy]]
    end
  end

  def compute_fill(border_set)
    xs = border_set.map(&:first)
    ys = border_set.map(&:last)
    min_ux = xs.min - 1
    max_ux = xs.max + 1
    min_uy = ys.min - 1
    max_uy = ys.max + 1

    exterior = Set.new([[min_ux, min_uy]])
    queue = [[min_ux, min_uy]]

    until queue.empty?
      ux, uy = queue.shift
      neighbours(ux, uy).each do |nx, ny|
        next unless (min_ux..max_ux).cover?(nx) && (min_uy..max_uy).cover?(ny)
        next if border_set.include?([nx, ny]) || exterior.include?([nx, ny])
        exterior << [nx, ny]
        queue << [nx, ny]
      end
    end

    interior = Set.new
    (min_ux..max_ux).each do |ux|
      (min_uy..max_uy).each do |uy|
        interior << [ux, uy] unless exterior.include?([ux, uy]) || border_set.include?([ux, uy])
      end
    end

    border_set | interior
  end

  def resolve_parsecs(coords)
    coords.map { |ux, uy| Parsec.find_by(x: ux, y: uy) }
  end

  def load_sector_names(rows)
    coords = rows.map { |r| [r[:sector_x], r[:sector_y]] }.uniq
    Sector.kept
          .where(x: coords.map(&:first), y: coords.map(&:last))
          .pluck(:x, :y, :name)
          .to_h { |x, y, name| [[x, y], name] }
  end

  def hex_label(row, sector_names)
    sector_name = sector_names.fetch([row[:sector_x], row[:sector_y]], "(#{row[:sector_x]},#{row[:sector_y]})")
    hex_code = format('%02d%02d', row[:hex_x], row[:hex_y])
    "#{sector_name} #{hex_code}"
  end

  def error(msg)
    { ok: false, error: msg }
  end
end
