class Api::JumpLogsController < Api::BaseController
  def index
    @jumps = JumpLog.all.order(arrive_year: :asc, arrive_day: :asc)
  end
end
