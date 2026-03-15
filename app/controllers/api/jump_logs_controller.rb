class Api::JumpLogsController < Api::BaseController
  def index
    @jumps = JumpLog
      .joins(
        'INNER JOIN parsecs from_parsecs ON from_parsecs.id = jump_logs.from_parsec_id ' \
        'INNER JOIN sectors from_sectors ON from_sectors.id = from_parsecs.sector_id ' \
        'INNER JOIN parsecs to_parsecs ON to_parsecs.id = jump_logs.to_parsec_id ' \
        'INNER JOIN sectors to_sectors ON to_sectors.id = to_parsecs.sector_id'
      )
      .select(
        'jump_logs.*',
        'from_parsecs.x AS from_x',
        'from_parsecs.y AS from_y',
        'to_parsecs.x AS to_x',
        'to_parsecs.y AS to_y',
        'from_sectors.name AS from_sector_name',
        'from_sectors.x AS from_sector_x',
        'from_sectors.y AS from_sector_y',
        'to_sectors.name AS to_sector_name',
        'to_sectors.x AS to_sector_x',
        'to_sectors.y AS to_sector_y'
      )
      .order(arrive_year: :asc, arrive_day: :asc)
  end
end
