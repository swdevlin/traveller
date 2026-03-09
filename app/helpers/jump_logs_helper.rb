module JumpLogsHelper
  def jump_chart_viewport(from_parsec, to_parsec = nil)
    mid_x = to_parsec ? ((from_parsec.x + to_parsec.x) / 2.0).round : from_parsec.x
    mid_y = to_parsec ? ((from_parsec.y + to_parsec.y) / 2.0).round : from_parsec.y

    ulx = mid_x - 3
    lrx = ulx + 7
    uly = mid_y + 4
    lry = uly - 9

    ulx = [ulx, from_parsec.x, to_parsec&.x].compact.min
    lrx = [lrx, from_parsec.x, to_parsec&.x].compact.max
    lry = [lry, from_parsec.y, to_parsec&.y].compact.min
    uly = [uly, from_parsec.y, to_parsec&.y].compact.max

    { ulx: ulx, uly: uly, lrx: lrx, lry: lry }
  end
end
